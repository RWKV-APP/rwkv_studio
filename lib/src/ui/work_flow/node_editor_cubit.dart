import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_card_style.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'node_editor_state.dart';

extension Ext on BuildContext {
  NodeEditorCubit get editorCubit {
    return BlocProvider.of<NodeEditorCubit>(this);
  }
}

class NodeEditorCubit extends Cubit<NodeEditorState> {
  NodeEditorCubit() : super(NodeEditorState.initial());

  void addNode(Offset position, NodePrototype proto) {
    final node = proto.create();
    if (proto.name == 'Const') {
      node.params['type'] = NodeDataType.any;
      node.params['value'] = Value(
        data: NodeDataType.any.defaultValue,
        type: NodeDataType.any,
        meta: null,
      );
    }
    double height = nodeHeaderHeight;
    final rows = max(node.allInputs.length, node.allOutputs.length);
    height += rows * (nodeSocketSpacing + nodeSocketSize) + nodeSocketSpacing;
    if (proto.name == 'Const') {
      height += nodeConstControlsHeight;
    }
    final card = NodeCardState(
      node: node,
      bounds: Rect.fromLTWH(position.dx, position.dy, 200, height),
    );
    emit(state.copyWith(cards: {...state.cards, card.id: card}));
  }

  void clear() {
    emit(
      state.copyWith(cards: {}, editingEdge: EdgeEditingState.empty, edges: {}),
    );
  }

  void link() {
    //
  }

  void run() {
    final group = NodeGroupPrototype.instance.create();
    for (final card in state.cards.values) {
      group.addNode(card.node);
    }

    NodeSocket? findSocket(NodeCardState card, String socketId) {
      for (final socket in card.node.allInputs) {
        if (socket.id == socketId) {
          return socket;
        }
      }
      for (final socket in card.node.allOutputs) {
        if (socket.id == socketId) {
          return socket;
        }
      }
      return null;
    }

    for (final edge in state.edges.values) {
      final fromCard = state.cards[edge.from];
      final toCard = state.cards[edge.targetNode];
      if (fromCard == null || toCard == null) {
        logw('edge ${edge.id} skipped: missing node');
        continue;
      }
      final fromSocket = findSocket(fromCard, edge.fromSocket);
      final toSocket = findSocket(toCard, edge.targetSocket);
      if (fromSocket == null || toSocket == null) {
        logw('edge ${edge.id} skipped: missing socket');
        continue;
      }
      if (edge.isControl) {
        if (fromSocket is NodeControlOut && toSocket is NodeControlIn) {
          group.connectControl(fromSocket, toSocket);
        } else {
          logw('edge ${edge.id} skipped: control socket mismatch');
        }
        continue;
      }
      if (fromSocket is NodeOutput && toSocket is NodeInput) {
        group.connectData(fromSocket, toSocket);
      } else {
        logw('edge ${edge.id} skipped: data socket mismatch');
      }
    }

    emit(state.copyWith(group: group));

    logi(
      'node graph run start nodes=${group.nodes.length} edges=${group.edges.length}',
    );
    final handle = state.engine.run(group);
    handle.subscribe((event) {
      switch (event) {
        case NodeStartEvent e:
          logd('node start ${e.nodeId} attempt=${e.attempt}');
        case NodeSuccessEvt e:
          logd(
            'node success ${e.nodeId} streaming=${e.streaming} index=${e.streamIndex}',
          );
        case NodeSuspendEvt e:
          logd('node suspend ${e.nodeId}');
        case NodeResumeEvt e:
          logd('node resume ${e.nodeId}');
        case NodeFailEvt e:
          logw('node fail ${e.nodeId} retryable=${e.retryable} ${e.error}');
        case NodeEndEvent e:
          logd(
            'node end ${e.nodeId} success=${e.success} duration=${e.duration.inMilliseconds}ms',
          );
      }
    });
    handle.done.then((result) {
      if (result.ok) {
        logi('node graph run finished');
      } else {
        loge('node graph run failed: ${result.error}');
      }
    });
  }

  void updateNodeParams(NodeId nodeId, Map<String, dynamic> params) {
    final card = state.cards[nodeId];
    if (card == null) return;
    final updated = _copyNodeWithParams(card.node, params);
    emit(
      state.copyWith(
        cards: {...state.cards, nodeId: card.copyWith(node: updated)},
      ),
    );
  }

  void startLink(NodeSocket socket, Offset position) {
    final pos = state.cards[socket.nodeId]!.getSocketPosition(socket);
    logd('startLink=>$pos');

    final socketEdges = state.edges.values.where((e) {
      return e.fromSocket == socket.id || e.targetSocket == socket.id;
    });
    final old = socketEdges.firstOrNull;
    if (old != null && socket is NodeInput) {
      final fromNode = state.cards[old.from]!;
      final toNode = state.cards[old.targetNode]!;
      final fromPos = fromNode.getOutputPosition(old.fromSocket);
      final toPos = toNode.getInputPosition(old.targetSocket);
      EdgeEditingState edit = EdgeEditingState(
        linkInput: true,
        from: fromNode.findSocket(old.fromSocket),
        target: toNode.findSocket(old.targetSocket),
        fromPos: fromPos,
        toPos: toPos,
        color: old.color,
      );
      emit(
        state.copyWith(
          editingEdge: edit,
          edges: {...state.edges}..remove(old.id),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        editingEdge: EdgeEditingState(
          from: socket,
          target: null,
          linkInput: socket is NodeOutput,
          fromPos: pos,
          toPos: pos,
          color: Colors.yellow,
        ),
      ),
    );
  }

  void updateLink(Offset position) {
    final pos = globalToCanvasCoordinate(position);
    final socket = _edgeSocketHitTest(pos);
    final old = state.editingEdge;
    if (socket == null) {
      final controlTarget = _controlTargetForPosition(pos);
      if (controlTarget == null) {
        emit(
          state.copyWith(editingEdge: old.copyWith(toPos: pos)..target = null),
        );
        return;
      }
      final card = state.cards[controlTarget.nodeId]!;
      final toPos = card.getSocketPosition(controlTarget);
      if (controlTarget.id == old.target?.id && toPos == old.toPos) {
        return;
      }
      emit(
        state.copyWith(
          editingEdge:
              state.editingEdge.copyWith(toPos: toPos)..target = controlTarget,
        ),
      );
      return;
    }
    final card = state.cards[socket.nodeId]!;
    final toPos = card.getSocketPosition(socket);
    if (socket.id == old.target?.id && toPos == old.toPos) {
      return;
    }
    logd('socket connected=>${socket.prototype.name}');
    emit(
      state.copyWith(
        editingEdge: state.editingEdge.copyWith(toPos: toPos)..target = socket,
      ),
    );
  }

  void endLink(Offset position) {
    logd('endLink=>$position');

    EdgeState? edge;
    if (state.editingEdge.isValid) {
      final from = state.editingEdge.linkInput
          ? state.editingEdge.from
          : state.editingEdge.target;
      final to = state.editingEdge.linkInput
          ? state.editingEdge.target
          : state.editingEdge.from;
      logd('${from!.nodeId}->${to!.nodeId} from: ${from.id}, to ${to.id}');
      edge = EdgeState(
        from: from.nodeId,
        targetNode: to.nodeId,
        fromSocket: from.id,
        targetSocket: to.id,
        color: state.editingEdge.color,
        isControl:
            from.prototype.type == NodeDataType.void_ ||
            to.prototype.type == NodeDataType.void_,
      );
    }
    emit(
      state.copyWith(
        editingEdge: EdgeEditingState.empty,
        edges: edge != null ? {...state.edges, edge.id: edge} : null,
      ),
    );
  }

  void removeNode(NodeCardState node) {
    emit(state.copyWith(cards: {...state.cards}..remove(node.id)));
  }

  void updateNodePosition(NodeCardState node, Offset globalPosition) {
    final topLeft = globalToCanvasCoordinate(globalPosition);
    emit(
      state.copyWith(
        cards: {
          ...state.cards,
          node.id: node.copyWith(
            bounds: Rect.fromLTWH(
              topLeft.dx,
              topLeft.dy,
              node.bounds.width,
              node.bounds.height,
            ),
          ),
        },
      ),
    );
  }

  Offset globalToCanvasCoordinate(Offset position) {
    final renderBox =
        state.keyCanvas.currentContext!.findRenderObject() as RenderBox?;
    return renderBox!.globalToLocal(position);
  }

  /// Todo: optimize: cache hit test variables, socket edge
  NodeSocket? _hitTestSocket(NodeCardState node, Offset position) {
    final isInput = state.editingEdge.linkInput;
    final from = state.editingEdge.from!;
    for (final socket
        in isInput ? node.node.allInputs : node.node.allOutputs) {
      final connected = state.edges.values.where((e) {
        return e.targetNode == node.id && e.targetSocket == socket.id;
      }).isNotEmpty;
      if (connected) {
        continue;
      }

      if (!state.engine.registry.isSocketLinkable(from, socket)) {
        continue;
      }
      final pos = node.getSocketPosition(socket);
      final dist = (position - pos).distanceSquared;
      if (dist.abs() < nodeSocketSize * nodeSocketSize) {
        return socket;
      }
    }
    return null;
  }

  NodeSocket? _edgeSocketHitTest(Offset pos) {
    NodeCardState? hitNode;
    for (final card in state.cards.values) {
      if (card.id == state.editingEdge.from?.nodeId) {
        continue;
      }
      if (card.hitTestBounds.contains(pos)) {
        hitNode = card;
      }
    }
    if (hitNode != null) {
      final hitSocket = _hitTestSocket(hitNode, pos);
      if (hitSocket != null) {
        return hitSocket;
      }
    }
    return null;
  }

  NodeControlIn? _controlTargetForPosition(Offset pos) {
    if (!_isControlLink()) return null;
    if (!state.editingEdge.linkInput) return null;
    for (final card in state.cards.values) {
      if (card.id == state.editingEdge.from?.nodeId) {
        continue;
      }
      if (!card.bounds.contains(pos)) continue;
      if (card.node.prototype.controlInputs.isNotEmpty) continue;
      if (card.node.inputs.isEmpty) continue;
      if (card.node.controlInputs.isEmpty) continue;
      return card.node.controlInputs.first;
    }
    return null;
  }

  bool _isControlLink() {
    final from = state.editingEdge.from;
    return from?.prototype.type == NodeDataType.void_;
  }

  Node _copyNodeWithParams(Node node, Map<String, dynamic> params) {
    if (node is OutputNode) {
      return OutputNode(
        id: node.id,
        inputs: node.inputs,
        controlInputs: node.controlInputs,
        controlOutputs: node.controlOutputs,
        prototype: node.prototype,
      )..params.addAll(params);
    }
    if (node is InputNode) {
      return InputNode(
        id: node.id,
        outputs: node.outputs,
        controlInputs: node.controlInputs,
        controlOutputs: node.controlOutputs,
        prototype: node.prototype,
      )..params.addAll(params);
    }
    return Node(
      id: node.id,
      inputs: node.inputs,
      outputs: node.outputs,
      controlInputs: node.controlInputs,
      controlOutputs: node.controlOutputs,
      prototype: node.prototype,
      params: params,
    );
  }
}
