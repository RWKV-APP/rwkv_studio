import 'dart:async';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_card.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/pair.dart';
import 'package:rxdart/rxdart.dart';

part 'node_editor_state.dart';

final addNodeProto = NodePrototype(
  name: 'Add',
  description: 'description',
  inputs: [
    SocketPrototype(name: 'a', description: '', type: NodeDataType.int),
    SocketPrototype(name: 'b', description: '', type: NodeDataType.int),
  ],
  outputs: [
    SocketPrototype(name: 'result', description: '', type: NodeDataType.int),
  ],
  executor: NodeExecutor(),
);

final multiplyNodeProto = NodePrototype(
  name: 'Multiply',
  description: 'description',
  inputs: [
    SocketPrototype(name: 'a', description: '', type: NodeDataType.int),
    SocketPrototype(name: 'b', description: '', type: NodeDataType.int),
  ],
  outputs: [
    SocketPrototype(name: 'result', description: '', type: NodeDataType.int),
  ],
  executor: NodeExecutor(),
);

extension Ext on BuildContext {
  NodeEditorCubit get editorCubit {
    return BlocProvider.of<NodeEditorCubit>(this);
  }
}

class NodeEditorCubit extends Cubit<NodeEditorState> {
  NodeEditorCubit() : super(NodeEditorState.initial()) {}

  @override
  Future<void> close() {
    return super.close();
  }

  void addNode(Offset position, NodePrototype proto) {
    final node = proto.create();
    final card = NodeCardState(
      node: node,
      bounds: Rect.fromLTWH(position.dx, position.dy, 160, 100),
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
    emit(
      state.copyWith(
        editingEdge: EdgeEditingState(
          output2input: socket is NodeOutput,
          fromPos: pos,
          fromNodeId: socket.nodeId,
          fromSocket: socket.id,
          toPos: pos,
          toNodeId: '',
          toSocket: '',
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
        state.copyWith(
          editingEdge: old.copyWith(toPos: pos, toNodeId: '', toSocket: ''),
        ),
      );
      return;
    }
    final card = state.cards[socket.nodeId]!;
    final toPos = card.getSocketPosition(socket);
    if (socket.id == old.toSocket && toPos == old.toPos) {
      return;
    }
    logd('socket connected=>${socket.prototype.name}');
    emit(
      state.copyWith(
        editingEdge: state.editingEdge.copyWith(
          toPos: toPos,
          toNodeId: socket.nodeId,
          toSocket: socket.id,
        ),
      ),
    );
  }

  void endLink(Offset position) {
    logd('endLink=>$position');

    EdgeState? edge;
    if (state.editingEdge.isValid) {
      final startNodeId = state.editingEdge.output2input
          ? state.editingEdge.fromNodeId
          : state.editingEdge.toNodeId;
      final endNodeId = state.editingEdge.output2input
          ? state.editingEdge.toNodeId
          : state.editingEdge.fromNodeId;
      final startSocketId = state.editingEdge.output2input
          ? state.editingEdge.fromSocket
          : state.editingEdge.toSocket;
      final endSocketId = state.editingEdge.output2input
          ? state.editingEdge.toSocket
          : state.editingEdge.fromSocket;
      logd('$startNodeId->$endNodeId from: $startSocketId, to $endSocketId');
      edge = EdgeState(
        from: startNodeId,
        to: endNodeId,
        fromSocket: startSocketId,
        toSocket: endSocketId,
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

  NodeSocket? _hitTestSocket(NodeCardState node, Offset position) {
    final isInput = state.editingEdge.output2input;
    for (final socket in isInput ? node.node.inputs : node.node.outputs) {
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
      if (card.id == state.editingEdge.fromNodeId) {
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
