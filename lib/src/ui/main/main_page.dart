import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/app/router.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/ui/common/theme_preview_page.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/ui/work_flow/work_flow_page.dart';

part 'navigation_panel_items.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final pageController = PageController();

  int selected = 2;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.fluent.brightness == Brightness.dark;
    return NavigationView(
      appBar: NavigationAppBar(
        // title: Text('RWKV Studio'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('RWKV Studio', style: context.typography.bodyStrong),
        ),
        actions: SizedBox(
          height: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              IconButton(
                icon: const Icon(FluentIcons.print),
                onPressed: () {
                  LogcatPanel.attachToRootOverlay(context);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
      paneBodyBuilder: (item, child) {
        return ColoredBox(
          color: dark
              ? Colors.black.withAlpha(100)
              : Colors.white.withAlpha(100),
          child: child ?? SizedBox(),
        );
      },
      pane: NavigationPane(
        // header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 220, openMinWidth: 120),
        selected: selected,
        displayMode: PaneDisplayMode.open,
        onItemPressed: (i) {
          if ({12, 7, 1}.contains(i)) {
            return;
          }
          setState(() {
            selected = i;
          });
        },
        items: buildNavItems(context),
        footerItems: buildNavFooterItems(context),
      ),
    );
  }
}
