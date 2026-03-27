part of 'flow_page.dart';

class NodeWidget extends StatelessWidget {
  final Node node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: .max,
        crossAxisAlignment: .stretch,
        children: [
          Container(
            height: 14,
            alignment: .centerLeft,
            padding: const .symmetric(horizontal: 4),
            child: Text(
              node.id,
              style: const TextStyle(fontSize: 10, fontWeight: .bold),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .end,
                    children: [
                      for (final port in node.inputPorts)
                        Container(
                          height: 20,
                          alignment: .centerLeft,
                          child: Text(
                            port.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      for (final port in node.outputPorts)
                        Container(
                          height: 20,
                          alignment: .centerRight,
                          child: Text(
                            port.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
