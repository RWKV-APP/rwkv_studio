import 'package:fluent_ui/fluent_ui.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class FlowPage extends StatefulWidget {
  const FlowPage({super.key});

  @override
  State<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends State<FlowPage> {
  late final controller = NodeFlowController<String, dynamic>(
    nodes: [
      Node<String>(
        id: 'node-1',
        type: 'input',
        position: const Offset(100, 100),
        data: 'Start',
        ports: [
          Port(
            id: 'out',
            name: 'Output',
            offset: const Offset(2, 40),
            type: .output,
            position: .right,
          ),
        ],
      ),
      Node<String>(
        id: 'node-2',
        type: 'output',
        position: const Offset(400, 100),
        data: 'End',
        ports: [
          Port(
            id: 'in',
            name: 'Input',
            offset: const Offset(-2, 40),
            type: .input,
          ),
        ],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out',
        targetNodeId: 'node-2',
        targetPortId: 'in',
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    //
  }

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<String, dynamic>(
      controller: controller,
      theme: NodeFlowTheme.dark.copyWith(
        connectionTheme: ConnectionTheme.dark.copyWith(
          style: ConnectionStyles.bezier,
        ),
        temporaryConnectionTheme: ConnectionTheme.dark.copyWith(
          style: ConnectionStyles.bezier,
        ),
      ),
      // behavior: .design,
      nodeBuilder: (context, node) =>
          Padding(padding: const EdgeInsets.all(16), child: Text(node.data)),
    );
  }
}
