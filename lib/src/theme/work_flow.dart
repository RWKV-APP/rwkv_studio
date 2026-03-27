import 'package:fluent_ui/fluent_ui.dart';
import 'package:vyuh_node_flow/connections.dart';
import 'package:vyuh_node_flow/nodes.dart';
import 'package:vyuh_node_flow/themes.dart';

class WorkFlowTheme {
  static NodeFlowTheme get darkTheme => NodeFlowTheme.dark.copyWith(
    connectionTheme: ConnectionTheme.dark.copyWith(
      style: ConnectionStyles.bezier,
    ),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.hierarchical,
      thickness: 0.4,
      color: Colors.grey[140],
    ),
  );

  static NodeFlowTheme get lightTheme => NodeFlowTheme.light.copyWith(
    backgroundColor: Colors.grey[10],
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.bezier,
    ),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.hierarchical,
      thickness: 0.4,
      color: Colors.grey[40],
    ),
    nodeTheme: NodeTheme.light.copyWith(
      contentStyle: const TextStyle(fontSize: 12),
    ),
  );
}
