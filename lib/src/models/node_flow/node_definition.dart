import 'package:rwkv_studio/src/models/node_flow/port_definition.dart';

class NodeDefinition {
  final String type;
  final List<PortDefinition> ports;

  Iterable<PortDefinition> get inputs => ports.where((p) => p.isInput);

  Iterable<PortDefinition> get outputs => ports.where((p) => !p.isInput);

  const NodeDefinition({required this.type, required this.ports});

  factory NodeDefinition.start() =>
      const NodeDefinition(type: 'Start', ports: [.controlOut]);

  factory NodeDefinition.end() =>
      const NodeDefinition(type: 'End', ports: [.controlIn]);
}
