import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: const .symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.all(2)),
            ),
            icon: const Icon(FluentIcons.cat, size: 12),
            onPressed: () {
              LogcatPanel.attachToRootOverlay(context);
            },
          ),
        ],
      ),
    );
  }
}
