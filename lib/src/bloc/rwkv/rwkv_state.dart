part of 'rwkv_cubit.dart';

typedef InstanceId = String;

class ModelBaseInfo {
  final String id;
  final String name;
  final String providerName;
  final String serviceId;

  bool get isRemote => providerName.isNotEmpty && serviceId.isNotEmpty;

  String get detailName =>
      [providerName, name].where((e) => e.isNotEmpty).join(': ');

  ModelBaseInfo._({
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

  factory ModelBaseInfo.fromRemoteService(
    ModelServiceWrap service,
    LoadedModel m,
  ) {
    return ModelBaseInfo._(
      id: m.info.id,
      name: m.info.name,
      providerName: service.sourceName,
      serviceId: service.id,
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
       config = config ?? GenerationConfig.initial();

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
  final List<ModelService> services;
  final Map<String, DecodeParam> decodeParams;

  Iterable<ModelInstanceState> get localInstances =>
      models.values.where((e) => !e.info.isRemote);

  RwkvState({
    required this.models,
    required this.services,
    required this.decodeParams,
  });

  factory RwkvState.initial() {
    return RwkvState(
      models: {},
      services: [],
      decodeParams: {'default': DecodeParam.initial()},
    );
  }

  RwkvState copyWith({
    Map<InstanceId, ModelInstanceState>? models,
    List<ModelService>? services,
    Map<String, DecodeParam>? decodeParams,
  }) {
    return RwkvState(
      models: models ?? this.models,
      services: services ?? this.services,
      decodeParams: decodeParams ?? this.decodeParams,
    );
  }
}
