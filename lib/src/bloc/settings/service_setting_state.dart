part of 'setting_cubit.dart';

class ModelSettingState extends Equatable {
  final List<RemoteService> remoteServices;
  final String modelListUrl;
  final List<ModelBackend> enabledBackends;
  final ModelServerSetting modelServer;

  @override
  List<Object?> get props => [
    remoteServices,
    modelListUrl,
    enabledBackends,
    modelServer,
  ];

  const ModelSettingState({
    required this.remoteServices,
    required this.modelListUrl,
    required this.enabledBackends,
    required this.modelServer,
  });

  factory ModelSettingState.initial() {
    return const ModelSettingState(
      enabledBackends: [],
      remoteServices: [],
      modelListUrl: '',
      modelServer: ModelServerSetting.empty,
    );
  }

  static final default_ = ModelSettingState(
    enabledBackends: ModelBackend.defaultBackends,
    remoteServices: [],
    modelListUrl:
        'https://aifasthub.com/meta-logic/config/resolve/main/model_config.json?download=true',
    modelServer: ModelServerSetting.empty,
  );

  Map<String, dynamic> toMap() {
    return {
      'remoteServices': remoteServices.map((e) => e.toMap()).toList(),
      'modelListUrl': modelListUrl,
      'enabledBackends': enabledBackends.map((e) => e.name).toList(),
      'modelServer': modelServer.toMap(),
    };
  }

  factory ModelSettingState.fromMap(dynamic map) {
    if (map == null) {
      return ModelSettingState.default_;
    }
    return ModelSettingState(
      remoteServices:
          (map['remoteServices'] as Iterable?)
              ?.map(RemoteService.fromMap)
              .toList() ??
          [],
      modelListUrl: map['modelListUrl'] ?? default_.modelListUrl,
      enabledBackends: ModelBackend.fromJson(map['enabledBackends']),
      modelServer: ModelServerSetting.fromMap(map['modelServer']),
    );
  }

  ModelSettingState copyWith({
    List<RemoteService>? remoteServices,
    String? modelListUrl,
    List<ModelBackend>? enabledBackends,
    ModelServerSetting? modelServer,
  }) {
    return ModelSettingState(
      remoteServices: remoteServices ?? this.remoteServices,
      modelListUrl: modelListUrl ?? this.modelListUrl,
      enabledBackends: enabledBackends ?? this.enabledBackends,
      modelServer: modelServer ?? this.modelServer,
    );
  }
}

class RemoteService extends Equatable {
  final String id;
  final String name;
  final String url;
  final String apiKey;
  final bool enabled;

  @override
  List<Object?> get props => [id, name, url, enabled, apiKey];

  RemoteService({
    required this.url,
    required this.id,
    required this.name,
    required this.enabled,
    required this.apiKey,
  });

  RemoteService copyWith({
    String? url,
    String? id,
    String? name,
    bool? enabled,
    String? apiKey,
  }) {
    return RemoteService(
      url: url ?? this.url,
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'enabled': enabled,
      'apiKey': apiKey,
    };
  }

  factory RemoteService.fromMap(dynamic map) {
    return RemoteService(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      enabled: map['enabled'] ?? true,
      apiKey: map['apiKey'] ?? '',
    );
  }
}
