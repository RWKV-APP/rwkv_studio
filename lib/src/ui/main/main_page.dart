import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/chat_page.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/ui/common/theme_preview_page.dart';
import 'package:rwkv_studio/src/ui/model/model_list_page.dart';
import 'package:rwkv_studio/src/ui/setting/setting_page.dart';
import 'package:rwkv_studio/src/ui/work_flow/work_flow_page.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _Nav {
  final String title;
  final IconData icon;
  final Widget body;
  final List<_Nav>? children;

  _Nav({
    required this.title,
    required this.icon,
    required this.body,
    this.children,
  });
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
      PaneItemExpander(
        icon: const WindowsIcon(WindowsIcons.pen_workspace),
        title: const Text('任务'),
        body: ChatPage(),
        initiallyExpanded: true,
        items: [
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.chat_bubbles),
            title: const Text('对话'),
            body: ChatPage(),
          ),
          PaneItem(
            icon: const WindowsIcon(FluentIcons.file_image),
            title: const Text('图片转文本'),
            body: ChatPage(),
          ),
          PaneItem(
            icon: const WindowsIcon(FluentIcons.text_document_edit),
            title: const Text('文本生成'),
            body: ChatPage(),
          ),
          PaneItem(
            icon: const WindowsIcon(FluentIcons.text_document_edit),
            title: const Text('文本转语音'),
            body: ChatPage(),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.music_info),
            title: const Text('音乐生成'),
            body: ChatPage(),
          ),
        ],
      ),
      PaneItemExpander(
        icon: const WindowsIcon(WindowsIcons.flow),
        title: const Text('工作流程'),
        body: SizedBox(),
        items: [
          PaneItem(
            icon: const WindowsIcon(FluentIcons.chart_template),
            title: const Text('Prompt 工程'),
            body: SizedBox(),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.search_and_apps),
            title: const Text('深度研究'),
            body: WorkFlowPage(),
          ),
          PaneItem(
            icon: const WindowsIcon(FluentIcons.search_data),
            title: const Text('知识库'),
            body: SizedBox(),
          ),
        ],
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.apps),
        title: const Text('模型管理'),
        body: ModelListPage(),
      ),
      PaneItemExpander(
        icon: const WindowsIcon(WindowsIcons.developer_tools),
        title: const Text('工具'),
        body: ModelListPage(),
        items: [
          PaneItem(
            icon: const WindowsIcon(FluentIcons.charticulator_linking_data),
            title: const Text('模型转换'),
            body: ModelListPage(),
          ),
        ],
      ),
      PaneItemSeparator(thickness: 60, color: Colors.transparent),
    ];

    final footer = <NavigationPaneItem>[
      PaneItemSeparator(),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.download),
        title: const Text('下载任务'),
        onTap: () {
          //
        },
        body: SizedBox(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.settings),
        title: const Text('设置'),
        body: SettingPage(),
      ),
    ];

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
      pane: NavigationPane(
        // header: const Text('RWKV Studio'),
        size: const NavigationPaneSize(openWidth: 220),
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
        items: items,
        footerItems: footer,
      ),
    );
  }
}
