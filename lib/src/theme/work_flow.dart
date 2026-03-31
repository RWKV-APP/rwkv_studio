import 'package:fluent_ui/fluent_ui.dart';
import 'package:vyuh_node_flow/connections.dart';
import 'package:vyuh_node_flow/nodes.dart';
import 'package:vyuh_node_flow/themes.dart';

class WorkFlowTheme {
  static const headerHeight = 20.0;
  static const lineHeight = 24.0;
  static const portSize = Size(6, 6);

  const WorkFlowTheme._();

  static NodeFlowTheme darkTheme = NodeFlowTheme.dark.copyWith(
    connectionTheme: ConnectionTheme.dark.copyWith(
      style: ConnectionStyles.bezier,
      strokeWidth: 1,
      selectedStrokeWidth: 2,
      color: Colors.grey[120],
      endPoint: ConnectionEndPoint.none,
      endGap: -2,
    ),
    temporaryConnectionTheme: ConnectionTheme.dark.copyWith(
      style: ConnectionStyles.bezier,
      strokeWidth: 1,
      selectedStrokeWidth: 2,
      color: Colors.grey[100],
      endPoint: ConnectionEndPoint.none,
      endGap: -2,
    ),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.hierarchical,
      thickness: 0.4,
      color: Colors.grey[140],
    ),
    nodeTheme: NodeTheme.dark.copyWith(
      contentStyle: const TextStyle(fontSize: 12),
      borderWidth: 1,
      selectedBorderWidth: 1,
      borderColor: Colors.grey[140],
      backgroundColor: Colors.grey[160],
    ),
  );

  static NodeFlowTheme get lightTheme => NodeFlowTheme.light.copyWith(
    backgroundColor: Colors.grey[10],
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.bezier,
      strokeWidth: 1,
      selectedStrokeWidth: 2,
      color: Colors.grey[100],
      endPoint: ConnectionEndPoint.circle,
      endGap: -2,
    ),
    temporaryConnectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.bezier,
      strokeWidth: 1,
      selectedStrokeWidth: 2,
      color: Colors.grey[100],
      endpointColor: Colors.grey[90],
      endPoint: ConnectionEndPoint.circle,
      endGap: -2,
    ),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.hierarchical,
      thickness: 0.3,
      color: Colors.grey[40],
    ),
    nodeTheme: NodeTheme.light.copyWith(
      contentStyle: const TextStyle(fontSize: 12),
      borderWidth: 1,
      selectedBorderWidth: 1,
      borderColor: Colors.grey[40],
      backgroundColor: Colors.white,
    ),
  );
}
