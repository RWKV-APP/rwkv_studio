part of 'flow_page.dart';

class _AddNodeMenu extends StatelessWidget {
  final Offset position;

  const _AddNodeMenu({required this.position});

  @override
  Widget build(BuildContext context) {
    return MenuFlyout(
      items: [
        for (var def in NodeFactory.nodeDefinitions)
          MenuFlyoutItem(
            text: Text(def.type),
            onPressed: () {
              context.nodeFlow.add(NodeFlowNodeAdded(position, def.type));
            },
          ),
      ],
    );
  }
}
