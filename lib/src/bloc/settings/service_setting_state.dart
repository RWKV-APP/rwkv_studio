part of 'setting_cubit.dart';

class ServiceSettingState {
  final List<RemoteService> remoteServices;
  final String modelListUrl;

  ServiceSettingState({
    required this.remoteServices,
    required this.modelListUrl,
  });

  static final initial = ServiceSettingState(
    remoteServices: [],
    modelListUrl:
        'https://aifasthub.com/meta-logic/config/resolve/main/model_config.json?download=true',
  );

  Map<String, dynamic> toMap() {
    return {
      'remoteServices': remoteServices.map((e) => e.toMap()).toList(),
      'modelListUrl': modelListUrl,
    };
  }

  factory ServiceSettingState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ServiceSettingState.initial;
    }
    return ServiceSettingState(
      remoteServices:
          (map['remoteServices'] as Iterable?)
              ?.map((e) => RemoteService.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelListUrl: map['modelListUrl'] ?? initial.modelListUrl,
    );
  }

  ServiceSettingState copyWith({
    List<RemoteService>? remoteServices,
    String? modelListUrl,
  }) {
    return ServiceSettingState(
      remoteServices: remoteServices ?? this.remoteServices,
      modelListUrl: modelListUrl ?? this.modelListUrl,
    );
  }
}

class RemoteService {
  final String id;
  final String name;
  final String url;
  final bool enabled;

  RemoteService({
    required this.url,
    required this.id,
    required this.name,
    required this.enabled,
  });

  RemoteService copyWith({
    String? url,
    String? id,
    String? name,
    bool? enabled,
  }) {
    return RemoteService(
      url: url ?? this.url,
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'url': url, 'enabled': enabled};
  }

  factory RemoteService.fromMap(Map<String, dynamic> map) {
    return RemoteService(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      enabled: map['enabled'] as bool,
    );
  }
}
