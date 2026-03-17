import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';

typedef InstanceId = String;

class ModelBaseInfo {
  final String id;
  final String name;
  final String providerName;
  final String serviceId;

  bool get isRemote => providerName.isNotEmpty && serviceId.isNotEmpty;

  bool get supportFunctionCall =>
      isRemote && !name.toLowerCase().contains('rwkv');

  String get detailName =>
      [providerName, name].where((e) => e.isNotEmpty).join(': ');

  const ModelBaseInfo._({
    required this.id,
    required this.name,
    required this.providerName,
    required this.serviceId,
  });

  factory ModelBaseInfo.fromModelInfo(ModelInfo info) {
    if (info.isRemote) {
      return ModelBaseInfo._(
        id: info.id,
        name: info.name,
        providerName: info.providerName,
        serviceId: info.serviceId,
      );
    }
    return ModelBaseInfo._(
      id: info.id,
      name: info.name,
      providerName: '',
      serviceId: '',
    );
  }

  factory ModelBaseInfo.remote({
    required String id,
    required String name,
    required String providerName,
    required String serviceId,
  }) {
    return ModelBaseInfo._(
      id: id,
      name: name,
      providerName: providerName,
      serviceId: serviceId,
    );
  }

  ModelInfo toModelInfo() {
    return ModelInfo.base(id: id, name: name, url: '');
  }
}

class ModelInstanceState {
  final InstanceId id;
  final RWKV rwkv;
  final ModelBaseInfo info;
  final GenerationState state;
  final GenerationConfig config;
  final DecodeParam decodeParam;

  ModelInstanceState({
    required this.rwkv,
    required this.info,
    required this.id,
    GenerationState? state,
    GenerationConfig? config,
    DecodeParam? decodeParam,
  }) : decodeParam = decodeParam ?? DecodeParam.initial(),
       state = state ?? GenerationState.initial(),
       config = config ?? const GenerationConfig();

  ModelInstanceState copyWith({
    RWKV? rwkv,
    ModelBaseInfo? info,
    GenerationState? state,
    GenerationConfig? config,
    DecodeParam? decodeParam,
  }) {
    return ModelInstanceState(
      rwkv: rwkv ?? this.rwkv,
      info: info ?? this.info,
      state: state ?? this.state,
      config: config ?? this.config,
      decodeParam: decodeParam ?? this.decodeParam,
      id: id,
    );
  }
}

class RwkvState {
  final Map<InstanceId, ModelInstanceState> models;
  final Map<String, DecodeParam> decodeParams;

  Iterable<ModelInstanceState> get localInstances =>
      models.values.where((e) => !e.info.isRemote);

  RwkvState({required this.models, required this.decodeParams});

  factory RwkvState.initial() {
    return RwkvState(
      models: {},
      decodeParams: {'default': DecodeParam.initial()},
    );
  }

  RwkvState copyWith({
    Map<InstanceId, ModelInstanceState>? models,
    Map<String, DecodeParam>? decodeParams,
  }) {
    return RwkvState(
      models: models ?? this.models,
      decodeParams: decodeParams ?? this.decodeParams,
    );
  }
}
