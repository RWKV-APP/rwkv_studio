import 'export.dart';

class SocketPrototype<T> {
  final String name;
  final String description;
  final NodeDataType<T> type;
  final Value? defaultValue;
  final bool required;

  SocketPrototype({
    required this.name,
    required this.description,
    required this.type,
    this.required = false,
    this.defaultValue,
  });
}

typedef SocketId = String;

class NodeSocket<T> {
  final NodeId nodeId;
  final SocketId id;
  final SocketPrototype<T> prototype;
  final Value? defaultValue;

  NodeSocket({
    required this.prototype,
    required this.id,
    required this.nodeId,
    this.defaultValue,
  });
}

class NodeInput extends NodeSocket {
  NodeInput({
    required super.prototype,
    required super.id,
    required super.nodeId,
  });
}

class NodeOutput extends NodeSocket {
  NodeOutput({
    required super.prototype,
    required super.id,
    required super.nodeId,
  });
}
