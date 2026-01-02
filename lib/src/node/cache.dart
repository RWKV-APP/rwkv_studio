import 'export.dart';

class Cache {
  final String hash;
  final Map<String, Value> outputs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration ttl;
  final bool crossRun;

  Cache({
    required this.ttl,
    required this.crossRun,
    required this.hash,
    required this.outputs,
    required this.createdAt,
    required this.updatedAt,
  });
}
