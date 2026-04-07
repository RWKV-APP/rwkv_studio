import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/model/_remote_provider_tab.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

import '_model_list.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

enum _SortType {
  modelSize('模型大小'),
  updateAt('更新时间'),
  fileSize('文件大小'),
  download('下载状态');

  final String name;

  const _SortType(this.name);
}

class _ModelListPageState extends State<ModelListPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRuntimeReady();
    });
  }

  Future<void> _ensureRuntimeReady() async {
    try {
      await context.modelManage.ensureRuntimeReady();
    } catch (e, s) {
      loge(AppException.wrap(e, s));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.fluent.brightness == Brightness.dark;
    final bgColor = dark ? context.fluent.cardColor : Colors.white;
    return ColoredBox(
      color: dark ? Colors.transparent : Colors.grey[20].withAlpha(100),
      child: TabView(
        currentIndex: _selectedTabIndex,
        onChanged: (index) => setState(() => _selectedTabIndex = index),
        closeButtonVisibility: CloseButtonVisibilityMode.never,
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        tabs: [
          Tab(
            icon: const Icon(FluentIcons.bulleted_list),
            text: const Text('模型列表'),
            body: ColoredBox(color: bgColor, child: const _LocalModel()),
            selectedBackgroundColor: WidgetStateColor.resolveWith(
              (s) => bgColor,
            ),
          ),
          Tab(
            icon: const Icon(FluentIcons.plug_connected),
            text: const Text('模型服务提供商'),
            body: ColoredBox(
              color: bgColor,
              child: const RemoteModelProviderTabBody(),
            ),
            selectedBackgroundColor: WidgetStateColor.resolveWith(
              (s) => bgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalModel extends StatefulWidget {
  const _LocalModel();

  @override
  State<_LocalModel> createState() => _LocalModelState();
}

class _LocalModelState extends State<_LocalModel> {
  List<String> _filters = [];

  _SortType _sortType = _SortType.modelSize;
  late final TextEditingController _catalogSearchController;

  Future<void> _refreshCatalog() async {
    await context.modelManage
        .updateModelList(remote: false)
        .withToast(context, success: 'Catalog refreshed');
  }

  @override
  void initState() {
    super.initState();
    _catalogSearchController = TextEditingController()
      ..addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _catalogSearchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<ModelInfo> _applyFilters(List<ModelInfo> models) {
    final managerState = context.modelManage.state;
    final groupNames = managerState.groups.map((e) => e.name).toSet();
    final tagNames = managerState.tags.map((e) => e.name).toSet();
    final selectedGroups = _filters.where(groupNames.contains).toSet();
    final selectedTags = _filters.where(tagNames.contains).toSet();
    final queryTerms = _catalogSearchController.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    final filtered = models.where((model) {
      final matchesGroup =
          selectedGroups.isEmpty || model.groups.any(selectedGroups.contains);
      final matchesTag =
          selectedTags.isEmpty || model.tags.any(selectedTags.contains);
      if (!matchesGroup || !matchesTag) {
        return false;
      }

      if (queryTerms.isEmpty) {
        return true;
      }

      final searchText = <String>[
        model.id,
        model.name,
        model.description,
        model.quantization,
        model.backend.name,
        model.backend.displayName,
        model.providerName,
        model.providerUrl,
        model.fileName,
        model.localPath,
        ...model.groups,
        ...model.tags,
      ].where((e) => e.isNotEmpty).join(' ').toLowerCase();

      return queryTerms.every(searchText.contains);
    }).toList();

    filtered.sort((a, b) {
      int compareNum(num a, num b) => b.compareTo(a);

      switch (_sortType) {
        case _SortType.modelSize:
          final value = compareNum(a.modelSize, b.modelSize);
          return value != 0 ? value : a.name.compareTo(b.name);
        case _SortType.updateAt:
          final value = compareNum(a.updatedAt, b.updatedAt);
          return value != 0 ? value : a.name.compareTo(b.name);
        case _SortType.fileSize:
          final value = compareNum(a.fileSize, b.fileSize);
          return value != 0 ? value : a.name.compareTo(b.name);
        case _SortType.download:
          final aState = managerState.modelStates[a.id]?.update;
          final bState = managerState.modelStates[b.id]?.update;
          final aRank = _downloadSortRank(a, aState);
          final bRank = _downloadSortRank(b, bState);
          final rankCompare = aRank.compareTo(bRank);
          if (rankCompare != 0) {
            return rankCompare;
          }
          final progressCompare = compareNum(
            aState?.progress.isFinite == true ? aState!.progress : -1,
            bState?.progress.isFinite == true ? bState!.progress : -1,
          );
          return progressCompare != 0
              ? progressCompare
              : a.name.compareTo(b.name);
      }
    });

    return filtered;
  }

  int _downloadSortRank(ModelInfo model, TaskUpdate? update) {
    if (model.localPath.isNotEmpty || update?.isCompleted == true) {
      return 0;
    }
    if (update?.isRunning == true) {
      return 1;
    }
    if (update?.isStopped == true) {
      return 2;
    }
    if (update?.isIdle == true) {
      return 3;
    }
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 12),
            _SortButton(
              sortType: _sortType,
              onSortTypeChanged: (v) {
                _sortType = v;
                _onQueryChanged();
              },
            ),
            const SizedBox(width: 12),
            _FilterButton(
              filter: _filters,
              onFilterChanged: (v) {
                _filters = v;
                _onQueryChanged();
              },
            ),
            const Spacer(),
            SizedBox(
              width: 320,
              child: TextBox(
                controller: _catalogSearchController,
                placeholder: '搜索 name, group, tag, backend...',
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(FluentIcons.search, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Button(
              onPressed: _refreshCatalog,
              child: const Row(children: [Icon(FluentIcons.refresh), Text("")]),
            ),
            const SizedBox(width: 6),
            const _SourceSelector(),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<ModelManageCubit, ModelManageState>(
            buildWhen: (p, c) => p.models != c.models,
            builder: (context, state) {
              final models = _applyFilters(state.models);
              return ModelList(models: models);
            },
          ),
        ),
      ],
    );
  }
}

final FlyoutController _controller = FlyoutController();

void _showDownloadMenu(BuildContext ctx, DownloadSource selected) {
  _controller.showFlyout<void>(
    barrierColor: Colors.black.withValues(alpha: 0.1),
    autoModeConfiguration: FlyoutAutoConfiguration(
      preferredMode: FlyoutPlacementMode.bottomCenter,
    ),
    barrierDismissible: true,
    dismissOnPointerMoveAway: false,
    dismissWithEsc: true,
    builder: (context) {
      return MenuFlyout(
        items: [
          MenuFlyoutItem(text: const Text('下载源'), onPressed: null),
          for (final s in [
            DownloadSource.auto,
            DownloadSource.aiFastHub,
            DownloadSource.huggingface,
            DownloadSource.hfMirror,
            DownloadSource.googleApis,
          ])
            ToggleMenuFlyoutItem(
              text: Text(s == DownloadSource.auto ? '自动' : s.name),
              value: s == selected,
              onChanged: (bool value) async {
                if (!value) {
                  return;
                }
                await context.modelManage
                    .setDownloadSource(s)
                    .withToast(context);
              },
            ),
        ],
      );
    },
  );
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ModelManageCubit, ModelManageState, DownloadSource>(
      selector: (state) => state.downloadSource,
      builder: (context, state) {
        return FlyoutTarget(
          controller: _controller,
          child: Button(
            onPressed: () => _showDownloadMenu(context, state),
            child: const Row(children: [Icon(FluentIcons.server), Text("")]),
          ),
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  final _SortType sortType;
  final ValueChanged<_SortType> onSortTypeChanged;
  final FlyoutController controller = FlyoutController();

  _SortButton({required this.sortType, required this.onSortTypeChanged});

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: controller,
      child: Button(
        onPressed: _showMenu,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.sort),
            const SizedBox(width: 8),
            Text(sortType.name),
          ],
        ),
      ),
    );
  }

  void _showMenu() {
    controller.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return MenuFlyout(
          items: [
            for (final s in _SortType.values)
              ToggleMenuFlyoutItem(
                text: Text(s.name),
                value: s == sortType,
                onChanged: (bool value) {
                  if (value) {
                    onSortTypeChanged(s);
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final List<String> filter;
  final ValueChanged<List<String>> onFilterChanged;
  final FlyoutController controller = FlyoutController();

  _FilterButton({required this.filter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: controller,
      child: Button(
        onPressed: () => _showFilter(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.filter),
            const SizedBox(width: 8),
            Text(filter.isEmpty ? '无过滤' : '${filter.length} filters'),
          ],
        ),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    final managerState = context.modelManage.state;

    controller.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        final filters = filter.toList();
        return FlyoutContent(
          constraints: const BoxConstraints(maxWidth: 320),
          child: StatefulBuilder(
            builder: (ctx, cs) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Groups', style: AppTextStyle.bodyBold),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final group in managerState.getDisplayGroups())
                        Checkbox(
                          checked: filters.contains(group.name),
                          onChanged: (value) {
                            if (value == true) {
                              filters.add(group.name);
                            } else {
                              filters.remove(group.name);
                            }
                            cs(() {});
                          },
                          content: Text(group.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Tags', style: AppTextStyle.bodyBold),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final tag in managerState.getDisplayTags())
                        Checkbox(
                          checked: filters.contains(tag.name),
                          content: Text(tag.name),
                          onChanged: (value) {
                            if (value == true) {
                              filters.add(tag.name);
                            } else {
                              filters.remove(tag.name);
                            }
                            cs(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      Button(
                        onPressed: () {
                          filters.clear();
                          cs(() {});
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          onFilterChanged(filters);
                          Flyout.of(context).close();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
