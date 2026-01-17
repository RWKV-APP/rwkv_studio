import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/model/_model_detail.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rxdart/rxdart.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

enum _SortType {
  modelSize('参数大小'),
  updateAt('更新时间'),
  fileSize('文件大小'),
  download('下载状态');

  final String name;

  const _SortType(this.name);
}

class _ModelListPageState extends State<ModelListPage> {
  late final _controllerSearchChange = StreamController<String>();
  late final _controllerSearch = TextEditingController();

  ModelInfo? _selectedModel;
  List<ModelInfo> _allModels = [];
  List<ModelInfo> _showModels = [];
  List<String> _filters = [];
  _SortType _sortType = _SortType.modelSize;

  @override
  void initState() {
    _controllerSearchChange.stream
        .map((event) => true)
        .timeout(Duration(milliseconds: 500))
        .onErrorReturn(false)
        .distinct((p, n) => p == n)
        .where((typing) => !typing)
        .skip(1)
        .listen((t) {
          filterByKeywords(_controllerSearch.text.trim().toLowerCase());
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allModels = context.modelManage.state.models;
      _showModels = _allModels;
      sortModel();
    });

    super.initState();
  }

  @override
  void dispose() {
    _controllerSearchChange.close();
    _controllerSearch.dispose();
    super.dispose();
  }

  void filterByKeywords(String keywords) {
    logd('search: $keywords');
    _filters = [];
    if (keywords.isEmpty) {
      _showModels = _allModels;
      sortModel();
      return;
    }

    final m = _allModels.where(
      (e) =>
          e.name.toLowerCase().contains(keywords) ||
          e.tags.any((t) => t.toLowerCase().contains(keywords)) ||
          e.backend.name.toLowerCase().contains(keywords),
    );
    final selected = m.any((e) => e.id == _selectedModel?.id);
    if (!selected) {
      _selectedModel = null;
    }
    _showModels = m.toList();
    sortModel();
  }

  void filterByFilters(List<String> filters) {
    _controllerSearch.text = '';
    if (filters.isEmpty) {
      _showModels = _allModels;
      sortModel();
      return;
    }
    final ms = _allModels.where(
      (e) =>
          filters.contains(e.backend.name) ||
          e.tags.any((t) => filters.contains(t)) ||
          e.groups.any((t) => filters.contains(t)),
    );
    final selected = ms.any((e) => e.id == _selectedModel?.id);
    if (!selected) {
      _selectedModel = null;
    }
    _showModels = ms.toList();
    sortModel();
  }

  void sortModel() {
    _showModels.sort((a, b) {
      if (a.localPath.isNotEmpty && b.localPath.isNotEmpty) {
        return 0;
      }
      if (a.localPath.isNotEmpty) {
        return -1;
      }
      if (b.localPath.isNotEmpty) {
        return 1;
      }
      return 0;
    });
    if (_sortType != _SortType.download) {
      _showModels.sort((a, b) {
        switch (_sortType) {
          case _SortType.modelSize:
            return -a.modelSize.compareTo(b.modelSize);
          case _SortType.updateAt:
            return -a.updatedAt.compareTo(b.updatedAt);
          case _SortType.fileSize:
            return -a.fileSize.compareTo(b.fileSize);
          case _SortType.download:
            return 0;
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 240),
      child: TextBox(
        controller: _controllerSearch,
        placeholder: 'name, tag, backend...',
        onChanged: (v) {
          _controllerSearchChange.add(v);
        },
        suffix: Padding(
          padding: .only(right: 12),
          child: Icon(FluentIcons.search, size: 16),
        ),
        suffixMode: .always,
      ),
    );
    final bar = Row(
      mainAxisSize: .max,
      mainAxisAlignment: .spaceBetween,
      children: [
        _SortButton(
          sortType: _sortType,
          onSortTypeChanged: (v) {
            _sortType = v;
            sortModel();
          },
        ),
        const SizedBox(width: 16),
        _FilterButton(
          filter: _filters,
          onFilterChanged: (f) {
            _filters = f;
            filterByFilters(f);
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            context.modelManage.updateConfig().withToast(context);
          },
          icon: Row(
            children: [
              Icon(FluentIcons.refresh),
              const SizedBox(width: 8),
              Text('更新列表'),
            ],
          ),
        ),
      ],
    );

    return Column(
      children: [
        BlocListener<ModelManageCubit, ModelManageState>(
          listenWhen: (previous, current) => previous.models != current.models,
          listener: (context, state) {
            setState(() {
              _allModels = state.models;
            });
          },
          child: SizedBox(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('浏览模型', style: AppTextStyle.heading),
              Spacer(),
              searchBar,
              const SizedBox(width: 16),
              Divider(direction: .vertical, size: 24),
              const SizedBox(width: 16),
              _SourceSelector(),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: .symmetric(horizontal: 8, vertical: 4),
                      child: bar,
                    ),
                    Divider(),
                    Expanded(
                      child: _ModelList(
                        models: _showModels,
                        selectedModelId: _selectedModel?.id ?? '',
                        onModelSelected: (model) {
                          setState(() {
                            _selectedModel = model;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(direction: .vertical),
              Expanded(
                flex: 5,
                child: _selectedModel == null
                    ? Center(
                        child: Text('未选择模型', style: AppTextStyle.bodySecondary),
                      )
                    : ModelDetail(model: _selectedModel!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelList extends StatelessWidget {
  final String selectedModelId;
  final ValueChanged<ModelInfo> onModelSelected;
  final List<ModelInfo> models;

  const _ModelList({
    required this.selectedModelId,
    required this.onModelSelected,
    this.models = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Center(child: Text('暂无模型', style: AppTextStyle.bodySecondary));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final selected = selectedModelId == model.id;
        return ListTile.selectable(
          selected: selected,
          onSelectionChange: (value) {
            if (value) {
              onModelSelected(model);
            }
          },
          trailing: model.localPath.isNotEmpty
              ? Icon(FluentIcons.status_circle_checkmark)
              : null,
          contentPadding: .only(right: 24),
          title: Text(
            model.name,
            style: AppTextStyle.bodyBold,
            overflow: .ellipsis,
            maxLines: 1,
          ),
        );
      },
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
          MenuFlyoutItem(
            leading: Text('下载源'),
            text: SizedBox(),
            onPressed: null,
          ),
          for (final s in [
            DownloadSource.auto,
            DownloadSource.aiFastHub,
            DownloadSource.huggingface,
            DownloadSource.hfMirror,
            DownloadSource.googleApis,
          ])
            ToggleMenuFlyoutItem(
              text: Text(s == DownloadSource.auto ? '自动选择' : s.name),
              value: s == selected,
              onChanged: (bool value) {
                context.modelManage.setDownloadSource(s);
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
        return IconButton(
          onPressed: () {
            _showDownloadMenu(context, state);
          },
          icon: Row(
            children: [
              FlyoutTarget(
                controller: _controller,
                child: const Icon(FluentIcons.server),
              ),
              const SizedBox(width: 8),
              Text(
                "下载源: ${state == DownloadSource.auto ? '自动选择' : state.name}",
              ),
            ],
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
      child: IconButton(
        icon: Row(
          children: [
            Icon(FluentIcons.sort),
            const SizedBox(width: 8),
            Text(sortType.name),
          ],
        ),
        onPressed: _showMenu,
      ),
    );
  }

  void _showMenu() async {
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
      child: IconButton(
        icon: Row(
          children: [
            Icon(FluentIcons.filter),
            const SizedBox(width: 8),
            Text(filter.isEmpty ? '无过滤' : '${filter.length} 个过滤'),
          ],
        ),
        onPressed: () {
          _showFilter(context);
        },
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
          constraints: BoxConstraints(maxWidth: 300),
          child: StatefulBuilder(
            builder: (ctx, cs) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '分组',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final g in managerState.groups)
                        Checkbox(
                          checked: filters.contains(g.name),
                          onChanged: (e) {
                            if (e == true) {
                              filters.add(g.name);
                            } else {
                              filters.remove(g.name);
                            }
                            cs(() {});
                          },
                          content: Text(g.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    '标签',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final tag in managerState.tags)
                        Checkbox(
                          checked: filters.contains(tag.name),
                          content: Text(tag.name),
                          onChanged: (e) {
                            if (e == true) {
                              filters.add(tag.name);
                            } else {
                              filters.remove(tag.name);
                            }
                            cs(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Spacer(),
                      Button(
                        child: Text('清空'),
                        onPressed: () {
                          filters.clear();
                          cs(() {});
                        },
                      ),
                      const SizedBox(width: 8.0),
                      Button(
                        onPressed: () {
                          onFilterChanged(filters);
                          Flyout.of(context).close();
                        },
                        child: const Text('确定'),
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
