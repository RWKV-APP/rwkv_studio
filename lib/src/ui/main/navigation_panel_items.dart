part of 'main_page.dart';

List<NavigationPaneItem> buildNavItems(BuildContext context) => [
  PaneItem(
    icon: const WindowsIcon(WindowsIcons.home),
    title: const Text('欢迎'),
    body: const ThemePreviewPage(),
  ),
  PaneItemExpander(
    icon: const WindowsIcon(WindowsIcons.pen_workspace),
    title: const Text('任务'),
    body: const SizedBox(),
    initiallyExpanded: true,
    items: [
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.chat_bubbles),
        title: const Text('对话'),
        body: const ChatPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(FluentIcons.text_document_edit),
        title: const Text('文本生成'),
        body: const TextGenerationPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.music_info),
        title: const Text('音乐生成'),
        body: const SizedBox(),
      ),
    ],
  ),
  PaneItemExpander(
    icon: const WindowsIcon(WindowsIcons.flow),
    title: const Text('工作流'),
    body: const SizedBox(),
    items: [
      PaneItem(
        icon: const WindowsIcon(WindowsIcons.search_and_apps),
        title: const Text('深度研究'),
        body: const WorkFlowPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(FluentIcons.search_data),
        title: const Text('知识库'),
        body: const SizedBox(),
      ),
    ],
  ),
  PaneItem(
    icon: const WindowsIcon(WindowsIcons.apps),
    title: const Text('模型管理'),
    body: const ModelListPage(),
  ),
  PaneItemExpander(
    icon: const WindowsIcon(FluentIcons.machine_learning),
    title: const Text('训练/微调'),
    body: const SizedBox(),
    items: [],
  ),
  PaneItemExpander(
    icon: const WindowsIcon(WindowsIcons.developer_tools),
    title: const Text('工具'),
    body: const ModelListPage(),
    items: [
      PaneItem(
        icon: const WindowsIcon(FluentIcons.charticulator_linking_data),
        title: const Text('模型转换'),
        body: const ModelListPage(),
      ),
    ],
  ),
  PaneItemSeparator(thickness: 60, color: Colors.transparent),
];

List<NavigationPaneItem> buildNavFooterItems(BuildContext context) => [
  PaneItemSeparator(),
  buildDownloadPaneItem(),
  PaneItem(
    icon: const WindowsIcon(WindowsIcons.settings),
    title: const Text('设置'),
    body: const SettingPage(),
  ),
];

