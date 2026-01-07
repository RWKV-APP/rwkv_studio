import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_card.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

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
  NodeEditorCubit() : super(NodeEditorState.initial());

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

    final socketEdges = state.edges.values.where((e) {
      return e.fromSocket == socket.id || e.targetSocket == socket.id;
    });
    final old = socketEdges.firstOrNull;
    if (old != null) {
      final fromPos = state.cards[old.from]!.getOutputPosition(old.fromSocket);
      final toPos = state.cards[old.targetNode]!.getInputPosition(
        old.targetSocket,
      );
      final linkInput = socket is NodeInput;
      EdgeEditingState edit = EdgeEditingState(
        linkInput: linkInput,
        fromNodeId: linkInput ? old.from : old.targetNode,
        fromSocket: linkInput ? old.fromSocket : old.targetSocket,
        targetNode: socket.nodeId,
        targetSocket: socket.id,
        fromPos: linkInput ? fromPos : toPos,
        toPos: linkInput ? toPos : fromPos,
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
          linkInput: socket is NodeOutput,
          fromPos: pos,
          fromNodeId: socket.nodeId,
          fromSocket: socket.id,
          toPos: pos,
          targetNode: '',
          targetSocket: '',
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
    if (socket.id == old.targetSocket && toPos == old.toPos) {
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
      final startNodeId = state.editingEdge.linkInput
          ? state.editingEdge.fromNodeId
          : state.editingEdge.targetNode;
      final endNodeId = state.editingEdge.linkInput
          ? state.editingEdge.targetNode
          : state.editingEdge.fromNodeId;
      final startSocketId = state.editingEdge.linkInput
          ? state.editingEdge.fromSocket
          : state.editingEdge.targetSocket;
      final endSocketId = state.editingEdge.linkInput
          ? state.editingEdge.targetSocket
          : state.editingEdge.fromSocket;
      logd('$startNodeId->$endNodeId from: $startSocketId, to $endSocketId');
      edge = EdgeState(
        from: startNodeId,
        targetNode: endNodeId,
        fromSocket: startSocketId,
        targetSocket: endSocketId,
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
    final isInput = state.editingEdge.linkInput;
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
