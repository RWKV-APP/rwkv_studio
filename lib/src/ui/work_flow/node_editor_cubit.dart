import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_card.dart';
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
    double height = nodeHeaderHeight;
    final rows = max(proto.inputs.length, proto.outputs.length);
    height += rows * (nodeSocketSpacing + nodeSocketSize) + nodeSocketSpacing;
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
      emit(
        state.copyWith(editingEdge: old.copyWith(toPos: pos)..target = null),
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
    for (final socket in isInput ? node.node.inputs : node.node.outputs) {
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
}
