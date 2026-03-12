import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/models/settings/model_server_settings_model.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

class ModelSettingsModel extends Equatable {
  final List<RemoteServiceModel> remoteServices;
  final String modelListUrl;
  final List<ModelBackend> enabledBackends;
  final ModelServerSettingsModel modelServer;

  @override
  List<Object?> get props => [
    remoteServices,
    modelListUrl,
    enabledBackends,
    modelServer,
  ];

  const ModelSettingsModel({
    required this.remoteServices,
    required this.modelListUrl,
    required this.enabledBackends,
    required this.modelServer,
  });

  factory ModelSettingsModel.initial() {
    return default_;
  }

  static final default_ = ModelSettingsModel(
    enabledBackends: ModelBackend.defaultBackends,
    remoteServices: [],
    modelListUrl:
        'https://aifasthub.com/meta-logic/config/resolve/main/model_config.json?download=true',
    modelServer: ModelServerSettingsModel.empty,
  );

  Map<String, dynamic> toMap() {
    return {
      'remoteServices': remoteServices.map((e) => e.toMap()).toList(),
      'modelListUrl': modelListUrl,
      'enabledBackends': enabledBackends.map((e) => e.name).toList(),
      'modelServer': modelServer.toMap(),
    };
  }

  factory ModelSettingsModel.fromMap(dynamic map) {
    if (map == null) {
      return ModelSettingsModel.default_;
    }
    return ModelSettingsModel(
      remoteServices:
          (map['remoteServices'] as Iterable?)
              ?.map(RemoteServiceModel.fromMap)
              .toList() ??
          [],
      modelListUrl: map['modelListUrl'] ?? default_.modelListUrl,
      enabledBackends: ModelBackend.fromJson(map['enabledBackends']),
      modelServer: ModelServerSettingsModel.fromMap(map['modelServer']),
    );
  }

  ModelSettingsModel copyWith({
    List<RemoteServiceModel>? remoteServices,
    String? modelListUrl,
    List<ModelBackend>? enabledBackends,
    ModelServerSettingsModel? modelServer,
  }) {
    return ModelSettingsModel(
      remoteServices: remoteServices ?? this.remoteServices,
      modelListUrl: modelListUrl ?? this.modelListUrl,
      enabledBackends: enabledBackends ?? this.enabledBackends,
      modelServer: modelServer ?? this.modelServer,
    );
  }
}

class RemoteServiceModel extends Equatable {
  final String id;
  final String name;
  final String url;
  final String apiKey;
  final bool enabled;

  @override
  List<Object?> get props => [id, name, url, enabled, apiKey];

  RemoteServiceModel({
    required this.url,
    required this.id,
    required this.name,
    required this.enabled,
    required this.apiKey,
  });

  RemoteServiceModel copyWith({
    String? url,
    String? id,
    String? name,
    bool? enabled,
    String? apiKey,
  }) {
    return RemoteServiceModel(
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

  factory RemoteServiceModel.fromMap(dynamic map) {
    return RemoteServiceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      enabled: map['enabled'] ?? true,
      apiKey: map['apiKey'] ?? '',
    );
  }
}
