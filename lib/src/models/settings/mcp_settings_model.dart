import 'package:rwkv_studio/src/utils/equatable.dart';

enum McpTransportType {
  stdio,
  streamableHttp;

  static McpTransportType fromName(String? name) {
    return values.firstWhere(
      (item) => item.name == name,
      orElse: () => McpTransportType.stdio,
    );
  }
}

class McpServerModel extends Equatable {
  final String id;
  final String name;
  final bool enabled;
  final McpTransportType transportType;

  final String command;
  final List<String> args;
  final String workingDirectory;
  final Map<String, String> environment;
  final bool includeParentEnvironment;

  final String url;
  final Map<String, String> headers;
  final int requestTimeoutMs;
  final bool openEventStream;
  final bool deleteSessionOnClose;

  const McpServerModel({
    required this.id,
    required this.name,
    required this.enabled,
    required this.transportType,
    required this.command,
    required this.args,
    required this.workingDirectory,
    required this.environment,
    required this.includeParentEnvironment,
    required this.url,
    required this.headers,
    required this.requestTimeoutMs,
    required this.openEventStream,
    required this.deleteSessionOnClose,
  });

  factory McpServerModel.empty() {
    return const McpServerModel(
      id: '',
      name: '',
      enabled: true,
      transportType: McpTransportType.stdio,
      command: '',
      args: [],
      workingDirectory: '',
      environment: {},
      includeParentEnvironment: true,
      url: '',
      headers: {},
      requestTimeoutMs: 30000,
      openEventStream: true,
      deleteSessionOnClose: true,
    );
  }

  factory McpServerModel.fromMap(dynamic map) {
    if (map == null) {
      return McpServerModel.empty();
    }

    return McpServerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      enabled: map['enabled'] ?? true,
      transportType: McpTransportType.fromName(map['transportType']),
      command: map['command'] ?? '',
      args: _stringListFrom(map['args']),
      workingDirectory: map['workingDirectory'] ?? '',
      environment: _stringMapFrom(map['environment']),
      includeParentEnvironment: map['includeParentEnvironment'] ?? true,
      url: map['url'] ?? '',
      headers: _stringMapFrom(map['headers']),
      requestTimeoutMs: map['requestTimeoutMs'] ?? 30000,
      openEventStream: map['openEventStream'] ?? true,
      deleteSessionOnClose: map['deleteSessionOnClose'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    enabled,
    transportType,
    command,
    args,
    workingDirectory,
    environment,
    includeParentEnvironment,
    url,
    headers,
    requestTimeoutMs,
    openEventStream,
    deleteSessionOnClose,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'transportType': transportType.name,
      'command': command,
      'args': args,
      'workingDirectory': workingDirectory,
      'environment': environment,
      'includeParentEnvironment': includeParentEnvironment,
      'url': url,
      'headers': headers,
      'requestTimeoutMs': requestTimeoutMs,
      'openEventStream': openEventStream,
      'deleteSessionOnClose': deleteSessionOnClose,
    };
  }

  McpServerModel copyWith({
    String? id,
    String? name,
    bool? enabled,
    McpTransportType? transportType,
    String? command,
    List<String>? args,
    String? workingDirectory,
    Map<String, String>? environment,
    bool? includeParentEnvironment,
    String? url,
    Map<String, String>? headers,
    int? requestTimeoutMs,
    bool? openEventStream,
    bool? deleteSessionOnClose,
  }) {
    return McpServerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      transportType: transportType ?? this.transportType,
      command: command ?? this.command,
      args: args ?? this.args,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      environment: environment ?? this.environment,
      includeParentEnvironment:
          includeParentEnvironment ?? this.includeParentEnvironment,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      requestTimeoutMs: requestTimeoutMs ?? this.requestTimeoutMs,
      openEventStream: openEventStream ?? this.openEventStream,
      deleteSessionOnClose: deleteSessionOnClose ?? this.deleteSessionOnClose,
    );
  }

  bool get isStdio => transportType == McpTransportType.stdio;

  bool get isStreamableHttp => transportType == McpTransportType.streamableHttp;
}

class McpSettingsModel extends Equatable {
  final List<McpServerModel> servers;
  final bool namespaceToolNames;
  final int maxToolRounds;

  const McpSettingsModel({
    required this.servers,
    required this.namespaceToolNames,
    required this.maxToolRounds,
  });

  factory McpSettingsModel.initial() {
    return const McpSettingsModel(
      servers: [],
      namespaceToolNames: false,
      maxToolRounds: 8,
    );
  }

  factory McpSettingsModel.fromMap(dynamic map) {
    if (map == null) {
      return McpSettingsModel.initial();
    }

    return McpSettingsModel(
      servers:
          (map['servers'] as Iterable?)?.map(McpServerModel.fromMap).toList() ??
          const [],
      namespaceToolNames: map['namespaceToolNames'] ?? false,
      maxToolRounds: map['maxToolRounds'] ?? 8,
    );
  }

  @override
  List<Object?> get props => [servers, namespaceToolNames, maxToolRounds];

  Map<String, dynamic> toMap() {
    return {
      'servers': servers.map((item) => item.toMap()).toList(),
      'namespaceToolNames': namespaceToolNames,
      'maxToolRounds': maxToolRounds,
    };
  }

  McpSettingsModel copyWith({
    List<McpServerModel>? servers,
    bool? namespaceToolNames,
    int? maxToolRounds,
  }) {
    return McpSettingsModel(
      servers: servers ?? this.servers,
      namespaceToolNames: namespaceToolNames ?? this.namespaceToolNames,
      maxToolRounds: maxToolRounds ?? this.maxToolRounds,
    );
  }
}

List<String> _stringListFrom(dynamic raw) {
  if (raw is Iterable) {
    return raw.map((item) => item.toString()).toList();
  }
  return const [];
}

Map<String, String> _stringMapFrom(dynamic raw) {
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
  return const {};
}
