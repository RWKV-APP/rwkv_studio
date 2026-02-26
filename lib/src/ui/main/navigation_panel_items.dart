part of 'main_page.dart';

final _downloadTaskFlyoutController = FlyoutController();

Widget todo() {
  return const Center(child: Text('TODO'));
}

String _itemTitle(NavBarItemType type) {
  switch (type) {
    case NavBarItemType.chat:
      return '对话';
    case NavBarItemType.textGeneration:
      return '文本生成';
    case NavBarItemType.modelManage:
      return '模型管理';
    case NavBarItemType.musicGeneration:
      return '音乐生成';
    case NavBarItemType.imageGeneration:
      return '图片生成';
    case NavBarItemType.workFlow:
      return '工作流';
    case NavBarItemType.downloadTask:
      return '下载任务';
    case NavBarItemType.settings:
      return '设置';
    case NavBarItemType.tools:
      return '工具';
    case NavBarItemType.fineTuning:
      return '微调';
    case NavBarItemType.convert:
      return '转换';
    case NavBarItemType.batchInfer:
      return '并行模式';
  }
}

Widget _itemIcon(NavBarItemType type) {
  switch (type) {
    case NavBarItemType.chat:
      return const WindowsIcon(WindowsIcons.chat_bubbles);
    case NavBarItemType.textGeneration:
      return const WindowsIcon(FluentIcons.text_document_edit);
    case NavBarItemType.modelManage:
      return const WindowsIcon(FluentIcons.product_list);
    case NavBarItemType.musicGeneration:
      return const WindowsIcon(WindowsIcons.music_info);
    case NavBarItemType.imageGeneration:
      return const WindowsIcon(WindowsIcons.image_export);
    case NavBarItemType.workFlow:
      return const WindowsIcon(WindowsIcons.flow);
    case NavBarItemType.downloadTask:
      return FlyoutTarget(
        controller: _downloadTaskFlyoutController,
        child: const WindowsIcon(WindowsIcons.download),
      );
    case NavBarItemType.settings:
      return const WindowsIcon(WindowsIcons.settings);
    case NavBarItemType.tools:
      return const WindowsIcon(WindowsIcons.developer_tools);
    case NavBarItemType.fineTuning:
      return const WindowsIcon(WindowsIcons.grid_view);
    case NavBarItemType.convert:
      return const WindowsIcon(WindowsIcons.refresh);
    case NavBarItemType.batchInfer:
      // return const WindowsIcon(FluentIcons.quad_column);
      return const WindowsIcon(FluentIcons.waffle);
  }
}

Widget? _itemBody(NavBarItemType type) {
  switch (type) {
    case NavBarItemType.chat:
      return const ChatPage();
    case NavBarItemType.textGeneration:
      return const TextGenerationPage();
    case NavBarItemType.modelManage:
      return const ModelListPage();
    case NavBarItemType.musicGeneration:
      return todo();
    case NavBarItemType.imageGeneration:
      return todo();
    case NavBarItemType.workFlow:
      return const WorkFlowPage();
    case NavBarItemType.downloadTask:
      return const SizedBox();
    case NavBarItemType.settings:
      return const SettingPage();
    case NavBarItemType.tools:
      return const SizedBox();
    case NavBarItemType.fineTuning:
      return todo();
    case NavBarItemType.convert:
      return todo();
    case NavBarItemType.batchInfer:
      return BatchInferPage.create();
  }
}

VoidCallback? _itemOnTap(NavBarItemType type) {
  switch (type) {
    case NavBarItemType.downloadTask:
      return () {
        _downloadTaskFlyoutController.showFlyout<void>(
          autoModeConfiguration: FlyoutAutoConfiguration(
            preferredMode: FlyoutPlacementMode.topCenter,
          ),
          barrierDismissible: true,
          dismissOnPointerMoveAway: false,
          dismissWithEsc: true,
          builder: (context) {
            return const _DownloadTaskFlyout();
          },
        );
      };
    default:
      return null;
  }
}

Widget? _itemBadge(NavBarItemType type) {
  switch (type) {
    case NavBarItemType.downloadTask:
      return _DownloadInfoBadge();
    default:
      return null;
  }
}

NavigationPaneItem _buildNavItem(NavBarItem item) {
  if (item.subitems != null) {
    return PaneItemExpander(
      icon: _itemIcon(item.type),
      title: Text(_itemTitle(item.type)),
      items: item.subitems!.map((item) => _buildNavItem(item)).toList(),
      body: const SizedBox(),
      onTap: () {},
    );
  } else {
    return PaneItem(
      icon: _itemIcon(item.type),
      body: _itemBody(item.type) ?? const SizedBox(),
      onTap: _itemOnTap(item.type),
      infoBadge: _itemBadge(item.type),
      title: Text(_itemTitle(item.type)),
    );
  }
}

List<NavigationPaneItem> buildNavItems(BuildContext context, AppState state) =>
    state.navBarItems
        .where((item) => !item.type.footer)
        .map((item) => _buildNavItem(item))
        .toList();

List<NavigationPaneItem> buildNavFooterItems(
  BuildContext context,
  AppState state,
) => [
  PaneItemSeparator(),
  ...state.navBarItems
      .where((item) => item.type.footer)
      .map((item) => _buildNavItem(item)),
];
