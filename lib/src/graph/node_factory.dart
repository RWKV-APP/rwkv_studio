import 'dart:math';
import 'dart:ui';

import 'package:rwkv_studio/src/models/node_flow/node_definition.dart';
import 'package:rwkv_studio/src/theme/work_flow.dart';
import 'package:uuid/uuid.dart';
import 'package:vyuh_node_flow/nodes.dart';
import 'package:vyuh_node_flow/ports.dart';

class NodeFactory {
  static const uuid = Uuid();

  static final nodeDefinitions = <NodeDefinition>[
    .start(),
    .end(),
    NodeDefinition(
      type: 'LLM',
      ports: [
        .controlIn,
        .controlOut,
        .input(name: 'tools', multiConnections: true),
      ],
    ),
    NodeDefinition(type: 'Tools', ports: [.controlOut]),
    NodeDefinition(type: 'Tool Call', ports: [.controlIn, .controlOut]),
    NodeDefinition(
      type: 'If',
      ports: [
        .controlIn,
        .output(name: 'True'),
        .output(name: 'False'),
      ],
    ),
    NodeDefinition(
      type: 'Loop',
      ports: [
        .controlIn,
        .output(name: 'Loop'),
        .output(name: 'Exit'),
      ],
    ),
  ];

  static final type2def = {for (var def in nodeDefinitions) def.type: def};

  static Node<T> create<T>(
    String type, {
    Offset position = Offset.zero,
    required T data,
  }) {
    final id = uuid.v4();

    final node = type2def[type];
    if (node == null) {
      throw ArgumentError('Unknown node type: $type');
    }

    final lines = max(node.inputs.length, node.outputs.length);

    final lineHeight = WorkFlowTheme.lineHeight;
    final headerHeight = WorkFlowTheme.headerHeight;
    final height = lines * lineHeight + headerHeight;
    final portHorizontalOffset = WorkFlowTheme.portSize.width / 4 - 2;
    final portOffset = headerHeight + 1;

    final ports = <Port>[];

    int inIndex = 0;
    int outIndex = 0;

    for (var i = 0; i < node.ports.length; i++) {
      final portDef = node.ports[i];
      final index = portDef.isInput ? inIndex : outIndex;
      if (portDef.isInput) {
        inIndex++;
      } else {
        outIndex++;
      }
      final p = Port(
        id: '$id-${portDef.name}',
        name: portDef.name,
        type: portDef.isInput ? .input : .output,
        offset: Offset(
          portDef.isInput ? portHorizontalOffset : -portHorizontalOffset,
          portOffset + lineHeight / 2 + index * lineHeight,
        ),
        size: WorkFlowTheme.portSize,
        position: portDef.isInput ? .left : .right,
        showLabel: true,
        multiConnections: portDef.multiConnections,
      );
      ports.add(p);
    }

    return Node<T>(
      id: id,
      type: type,
      position: position,
      size: Size(100, height + 2),
      data: data,
      ports: ports,
    );
  }
}
