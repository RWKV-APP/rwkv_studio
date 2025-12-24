import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/theme_preview_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/ui/work_flow/work_flow_page.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = <NavigationPaneItem>[
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.home),
        title: const Text('欢迎'),
        body: ThemePreviewPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.chat_bubbles),
        title: const Text('对话'),
        body: ChatPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.flow),
        title: const Text('工作流程'),
        body: WorkFlowPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.apps),
        title: const Text('模型管理'),
        body: ModelListPage(),
      ),
    ];

    final footer = <NavigationPaneItem>[
      PaneItemExpander(
        icon: const WindowsIcon(WindowsIcons.download),
        title: const Text('下载任务'),
        onTap: () {
          //
        },
        items: [],
        body: SizedBox(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.settings),
        title: const Text('设置'),
        body: Material(child: SettingPage()),
      ),
    ];

    return NavigationView(
      pane: NavigationPane(
        header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 200),
        selected: selected,
        displayMode: PaneDisplayMode.compact,
        onItemPressed: (i) {
          setState(() {
            selected = i;
          });
        },
        items: items,
        footerItems: footer,
      ),
    );
  }
}
