import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/app/router.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/ui/common/theme_preview_page.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/ui/work_flow/work_flow_page.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

part 'navigation_panel_items.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final pageController = PageController();

  int selected = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.modelManage.init();
      AppAssets.init().withToast(context);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        return Mica(
          backgroundColor: Colors.white.withAlpha(160),
          child: child ?? SizedBox(),
        );
      },
      pane: NavigationPane(
        // header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 220, openMinWidth: 120),
        selected: selected,
        displayMode: PaneDisplayMode.compact,
        onItemPressed: (i) {
          logd('selected: $i');
          if ({14, 12, 7, 1}.contains(i)) {
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
