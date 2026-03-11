class ModelServerSetting {
  final String host;
  final int port;
  final bool enabled;
  final bool onlyLocalModel;

  const ModelServerSetting({
    required this.host,
    required this.port,
    required this.enabled,
    required this.onlyLocalModel,
  });

  static const ModelServerSetting empty = ModelServerSetting(
    host: '127.0.0.1',
    port: 8086,
    enabled: false,
    onlyLocalModel: true,
  );

  Map toMap() {
    return {
      'host': host,
      'port': port,
      'enabled': enabled,
      'onlyLocalModel': onlyLocalModel,
    };
  }

  factory ModelServerSetting.fromMap(dynamic map) {
    if (map == null) return empty;
    return ModelServerSetting(
      host: map['host'] ?? '127.0.0.1',
      port: map['port'] ?? 8086,
      enabled: map['enabled'] ?? false,
      onlyLocalModel: map['onlyLocalModel'] ?? true,
    );
  }

  ModelServerSetting copyWith({
    String? host,
    int? port,
    bool? enabled,
    bool? onlyLocalModel,
  }) {
    return ModelServerSetting(
      host: host ?? this.host,
      port: port ?? this.port,
      enabled: enabled ?? this.enabled,
      onlyLocalModel: onlyLocalModel ?? this.onlyLocalModel,
    );
  }
}
