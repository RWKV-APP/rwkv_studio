import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> with RwkvInterface {
  RwkvCubit() : super(RwkvState.initial());

  Future init() async {
    //
  }

  Future setRemoteServiceList(Map<String, String> id2url) async {
    final serviceIds = id2url.keys;
    final removed = <String>[];
    for (final instance in state.models.values) {
      final info = instance.info;
      if (info.isRemote) {
        if (!serviceIds.contains(info.serviceId)) {
          removed.add(instance.id);
        }
      }
    }

    if (removed.isNotEmpty) {
      final models = {...state.models};
      models.removeWhere((k, v) => removed.contains(k));
      emit(state.copyWith(models: models));
      logi('remove ${removed.length} expired instances');
    }

    final added = serviceIds
        .where((id) => !state.services.any((e) => e.id == id))
        .toList();

    final services = <RwkvServiceClient>[];
    for (final id in serviceIds) {
      final cli = RwkvServiceClient(id: id, name: id, url: id2url[id]!);
      services.add(cli);
    }
    emit(state.copyWith(services: services));

    if (added.isNotEmpty) {
      logi('${added.length} new services');
      await _syncServiceStatus(added) //
          .timeout(Duration(seconds: 2))
          .catchError((e, s) => loge(e));
    }
  }

  ModelInstanceState? getModelInstance(String? modelInstanceId) {
    return state.models[modelInstanceId];
  }

  @override
  Future<List<String>> getLoadedInstance(String modelId) async {
    return state.models.values
        .where((e) => e.info.id == modelId)
        .map((e) => e.id)
        .toList();
  }

  @override
  Future stop(String instanceId) async {
    logd('stop $instanceId');
    final instance = state.models[instanceId]!;
    if (!instance.state.isGenerating) {
      logw('not generating');
    }
    await instance.rwkv.stopGenerate();
  }

  Future setDecodeParam(String modelInstanceId, DecodeParam param) async {
    final instance = state.models[modelInstanceId]!;
    await instance.rwkv.setDecodeParam(param);
  }

  @override
  Stream<GenerationResponse> chat(
    List<String> message,
    String instanceId,
    DecodeParam param,
    GenerationConfig config,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    await _syncModelConfig(instanceId, param, config);
    try {
      yield* instance.rwkv
          .chat(
            ChatParam(messages: message, model: instanceId, reasoning: 'high'),
          )
          .timeout(Duration(seconds: 30));
    } catch (e, s) {
      loge(e);
      loge(s);
      rethrow;
    }
  }

  @override
  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    DecodeParam decodeParam,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    await _syncModelConfig(instanceId, decodeParam, null);
    await instance.rwkv.clearState();
    try {
      yield* instance.rwkv.generate(
        GenerationParam(prompt: prompt, model: instanceId),
      );
    } catch (e, s) {
      loge(e);
      loge(s);
      rethrow;
    }
  }

  Future release(String modelInstanceId) async {
    final instance = state.models[modelInstanceId];
    if (instance == null) throw "Model not found";
    await instance.rwkv.release();
    logd('model released $modelInstanceId');
    emit(state.copyWith(models: {...state.models}..remove(modelInstanceId)));
  }

  @override
  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) async* {
    RWKV rwkv;
    String? instanceId;
    if (modelInfo.isRemote) {
      final service = state.services
          .where((e) => e.id == modelInfo.serviceId)
          .firstOrNull;
      if (service == null) {
        yield ModelLoadState.error(
          modelInfo.id,
          "no service found for ${modelInfo.providerName}",
        );
        return;
      }
      final res = await service.create(modelInfo.id);
      rwkv = res.rwkv;
      instanceId = res.info.instanceId;
    } else {
      rwkv = RWKV.isolated();
    }

    await rwkv.init(InitParam(logLevel: RWKVLogLevel.verbose));
    yield ModelLoadState.loading(modelInfo.id);
    try {
      await rwkv.loadModel(
        LoadModelParam(
          modelPath: modelInfo.localPath,
          tokenizerPath: AppAssets.rwkvVocab20230424,
        ),
      );
    } catch (e) {
      yield ModelLoadState.error(modelInfo.id, e);
      return;
    }
    final instance = ModelInstanceState(
      rwkv: rwkv,
      id: instanceId ?? "local_${modelInfo.id}",
      info: ModeBaseInfo.fromModelInfo(modelInfo),
    );
    emit(state.copyWith(models: {...state.models, instance.id: instance}));
    yield ModelLoadState.loaded(modelInfo.id, modelInfo.name, instance.id);
    rwkv.generationStateStream().listen((e) {
      final inst = state.models[instance.id];
      if (inst?.state == e) {
        return;
      }
      emit(
        state.copyWith(
          models: {
            ...state.models,
            instance.id: inst!.copyWith(state: e),
          },
        ),
      );
    });
  }

  Future _syncModelConfig(
    String instanceId,
    DecodeParam param, [
    GenerationConfig? config,
  ]) async {
    ModelInstanceState instance = state.models[instanceId]!;
    bool updated = false;
    if (instance.config != config) {
      await instance.rwkv.setGenerationConfig(config!);
      instance = instance.copyWith(config: config);
      updated = true;
    }
    if (instance.decodeParam != param) {
      await instance.rwkv.setDecodeParam(param);
      instance = instance.copyWith(decodeParam: param);
      updated = true;
    }
    if (updated) {
      emit(state.copyWith(models: {...state.models, instanceId: instance}));
    }
  }

  Future _syncServiceStatus(List<String> serviceIds) async {
    final services = state.services.where((e) => serviceIds.contains(e.id));

    Map<String, ModelInstanceState> instances = {};
    for (final service in services) {
      await service.status();
      final ms = await service.getLoadedModels();
      for (final m in ms) {
        instances[m.info.instanceId] = ModelInstanceState(
          rwkv: m.rwkv,
          id: m.info.modelId,
          info: ModeBaseInfo(
            id: m.info.modelId,
            name: m.info.name,
            providerName: service.name,
            serviceId: service.id,
          ),
        );
      }
    }

    if (instances.isNotEmpty) {
      logd('connected ${instances.length} instances from remote service');
      emit(state.copyWith(models: {...instances, ...state.models}));
    }
  }

  @override
  Future<String> getModelName(String instanceId) async {
    final model = state.models[instanceId];
    if (model == null) return throw "Model not found, instanceId: $instanceId";
    return model.info.name;
  }
}
