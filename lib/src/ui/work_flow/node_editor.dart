import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

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

const nodeHeaderHeight = 18.0;
const nodeSocketHeight = 24.0;
const nodeSocketSpacing = 6.0;

final dataType2color = {
  NodeDataType.int: Colors.red.shade800,
  NodeDataType.float: Colors.blue.shade800,
  NodeDataType.string: Colors.green.shade800,
  NodeDataType.bool: Colors.yellow.shade800,
  NodeDataType.list: Colors.purple.shade800,
  NodeDataType.map: Colors.orange.shade800,
  NodeDataType.any: Colors.grey.shade800,
};

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _NodeEditorState();
}

class LinkLine {
  final Node start;
  final Node? end;
  final Color color;

  LinkLine({required this.start, required this.end, required this.color});
}

class _NodeEditorState extends State<NodeEditor> {
  final FocusNode focusNode = FocusNode();

  final node2rect = <NodeId, Rect>{};
  final nodes = <Node>[];

  final lines = <LinkLine>[];

  final NodeGroup group = NodeGroupPrototype.instance.create();

  Offset dragDownPos = Offset.zero;

  void _onKeyEvent(KeyEvent event) {
    logd('key event: $event');
  }

  void _onRightClick() {
    nodes.add(addNodeProto.create());
    node2rect[nodes.last.id] = Rect.fromLTWH(100, 100, 160, 100);
    logd('node added');
    setState(() {});
  }

  void _link() {
    lines.clear();
    Node? node;
    for (final n in nodes) {
      if (node != null) {
        final start = node2rect[node.id]!.topLeft;
        final end = node2rect[n.id]!.topLeft;
        lines.add(
          LinkLine(start: node, end: n, color: Colors.yellow.shade800),
        );
      }
      node = n;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onSecondaryTap: _onRightClick,
        child: Container(
          color: Colors.grey.shade900,
          child: Stack(
            children: [
              for (final line in lines)
                CustomPaint(
                  painter: _LineCustomPainter(
                    start: node2rect[line.start.id]!.topLeft,
                    end: node2rect[line.end!.id]!.topLeft,
                    color: line.color,
                  ),
                ),
              for (final node in nodes)
                Positioned(
                  top: node2rect[node.id]?.top ?? 0,
                  left: node2rect[node.id]?.left ?? 0,
                  height: node2rect[node.id]?.height ?? 100,
                  width: node2rect[node.id]?.width ?? 100,
                  child: DragEditable(
                    handleRadius: 0,
                    onStartUpdatePosition: (offset) {
                      dragDownPos = offset;
                    },
                    onUpdate: (details) {
                      final rb = context.findRenderObject() as RenderBox?;
                      final local = rb!.globalToLocal(details.globalPosition);
                      final pos = local - dragDownPos;
                      node2rect[node.id] = Rect.fromLTWH(
                        pos.dx,
                        pos.dy,
                        node2rect[node.id]?.width ?? 100,
                        node2rect[node.id]?.height ?? 100,
                      );
                      setState(() {});
                    },
                    child: GestureDetector(
                      onDoubleTap: () {
                        nodes.remove(node);
                        node2rect.remove(node.id);
                        setState(() {});
                      },
                      child: NodeView(
                        node: node,
                        onLinkIn: (s, offset) {
                          //
                        },
                        onLinkOut: (s, offset) {
                          //
                        },
                      ),
                    ),
                  ),
                ),

              Positioned(
                right: 20,
                top: 20,
                child: Column(
                  children: [
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        nodes.clear();
                        node2rect.clear();
                        setState(() {});
                      },
                      icon: Icon(Icons.cleaning_services_sharp),
                    ),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _link();
                      },
                      icon: Icon(Icons.link),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NodeView extends StatelessWidget {
  final Node node;
  final Function(SocketId socket, Offset offset) onLinkOut;
  final Function(SocketId socket, Offset offset) onLinkIn;

  const NodeView({
    super.key,
    required this.node,
    required this.onLinkIn,
    required this.onLinkOut,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<NodeInput?, NodeOutput?>>[];
    for (final input in node.inputs) {
      rows.add(MapEntry(input, null));
    }
    for (final (index, output) in node.outputs.indexed) {
      if (rows.length - 1 >= index) {
        rows[index] = MapEntry(rows[index].key, output);
      } else {
        rows.add(MapEntry(null, output));
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey.shade800,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: nodeHeaderHeight,
                padding: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  color: Colors.green,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: nodeHeaderHeight + nodeSocketSpacing),
              for (final r in rows)
                Container(
                  height: nodeSocketHeight,
                  padding: EdgeInsetsGeometry.symmetric(
                    vertical: nodeSocketSpacing,
                  ),
                  child: Row(
                    children: [
                      if (r.key != null)
                        Flexible(child: NodeSocketView(socket: r.key!)),
                      Spacer(),
                      if (r.value != null)
                        Flexible(child: NodeSocketView(socket: r.value!)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class NodeSocketView extends StatelessWidget {
  final NodeSocket socket;

  const NodeSocketView({super.key, required this.socket});

  @override
  Widget build(BuildContext context) {
    final output = socket is NodeOutput;

    final textStyle = TextStyle(
      color: Colors.grey.shade300,
      fontSize: 12,
      height: 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: output
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (output)
          Text(
            socket.prototype.name,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        if (output) const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: dataType2color[socket.prototype.type],
          ),
        ),
        if (!output) const SizedBox(width: 4),
        if (!output) Text(socket.prototype.name, style: textStyle),
      ],
    );
  }
}

class _LineCustomPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  late final _paint = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  _LineCustomPainter({
    super.repaint,
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(start, end, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
