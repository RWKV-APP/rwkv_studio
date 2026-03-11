import 'package:rwkv_studio/src/utils/equatable.dart';

class ModelServerSettingsModel extends Equatable {
  final String host;
  final int port;
  final bool enabled;
  final bool onlyLocalModel;

  const ModelServerSettingsModel({
    required this.host,
    required this.port,
    required this.enabled,
    required this.onlyLocalModel,
  });

  static const ModelServerSettingsModel empty = ModelServerSettingsModel(
    host: '127.0.0.1',
    port: 8086,
    enabled: false,
    onlyLocalModel: true,
  );

  @override
  List<Object?> get props => [host, port, enabled, onlyLocalModel];

  Map toMap() {
    return {
      'host': host,
      'port': port,
      'enabled': enabled,
      'onlyLocalModel': onlyLocalModel,
    };
  }

  factory ModelServerSettingsModel.fromMap(dynamic map) {
    if (map == null) return empty;
    return ModelServerSettingsModel(
      host: map['host'] ?? '127.0.0.1',
      port: map['port'] ?? 8086,
      enabled: map['enabled'] ?? false,
      onlyLocalModel: map['onlyLocalModel'] ?? true,
    );
  }

  ModelServerSettingsModel copyWith({
    String? host,
    int? port,
    bool? enabled,
    bool? onlyLocalModel,
  }) {
    return ModelServerSettingsModel(
      host: host ?? this.host,
      port: port ?? this.port,
      enabled: enabled ?? this.enabled,
      onlyLocalModel: onlyLocalModel ?? this.onlyLocalModel,
    );
  }
}
