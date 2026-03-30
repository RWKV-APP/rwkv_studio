part of 'flow_page.dart';

class _NodeWidget extends StatelessWidget {
  final Node node;

  final portTextStyle = const TextStyle(fontSize: 10, height: 1);

  const _NodeWidget({required this.node});

  @override
  Widget build(BuildContext context) {
    final isStart = node.type.toLowerCase() == 'start';
    final isEnd = node.type.toLowerCase() == 'end';

    Color color = const Color(0xFF8BA8CB);
    if (isStart) {
      color = Colors.green.lighter;
    } else if (isEnd) {
      color = Colors.red.lighter;
    }

    return Container(
      decoration: BoxDecoration(borderRadius: .circular(7)),
      clipBehavior: .antiAlias,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Container(
            color: color,
            height: WorkFlowTheme.headerHeight,
            padding: const .symmetric(horizontal: 4),
            alignment: .centerLeft,
            child: Text(
              node.type,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: .w500,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
