part of 'main_page.dart';

List<NavigationPaneItem> buildNavItems(BuildContext context) => [
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
        title: const Text('视觉问答'),
        body: ChatPage(),
      ),
      PaneItem(
        icon: const WindowsIcon(FluentIcons.text_document_edit),
        title: const Text('文本生成'),
        body: TextGenerationPage(),
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
    title: const Text('工作流'),
    body: SizedBox(),
    items: [
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
    icon: const WindowsIcon(FluentIcons.machine_learning),
    title: const Text('训练/微调'),
    body: SizedBox(),
    items: [],
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

List<NavigationPaneItem> buildNavFooterItems(BuildContext context) => [
  PaneItemSeparator(),
  PaneItem(
    icon: const WindowsIcon(WindowsIcons.download),
    title: const Text('下载任务'),
    onTap: () {
      Navigator.pushNamed(context, AppRouter.demo);
    },
    body: SizedBox(),
  ),
  PaneItem(
    icon: const WindowsIcon(WindowsIcons.settings),
    title: const Text('设置'),
    body: SettingPage(),
  ),
];
