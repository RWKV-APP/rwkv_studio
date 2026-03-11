import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/model/_model_detail.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rxdart/rxdart.dart';

import '_model_list.dart';

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key});

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

enum _SortType {
  modelSize('Model size'),
  updateAt('Updated time'),
  fileSize('File size'),
  download('Download');

  final String name;

  const _SortType(this.name);
}

class _ModelListPageState extends State<ModelListPage> {
  late final StreamController<String> _controllerSearchChange;
  late final TextEditingController _controllerSearch;

  String? _selectedModelId;
  List<ModelInfo> _allModels = [];
  List<ModelInfo> _showModels = [];
  List<String> _filters = [];
  _SortType _sortType = _SortType.modelSize;

  @override
  void initState() {
    super.initState();
    _controllerSearchChange = StreamController<String>();
    _controllerSearch = TextEditingController();

    _controllerSearchChange.stream
        .map((event) => true)
        .timeout(const Duration(milliseconds: 500))
        .onErrorReturn(false)
        .distinct((p, n) => p == n)
        .where((typing) => !typing)
        .skip(1)
        .listen((_) {
          filterByKeywords(_controllerSearch.text.trim().toLowerCase());
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRuntimeReady();
      _allModels = context.modelManage.state.allModels;
      _showModels = _allModels;
      sortModel();
    });
  }

  @override
  void dispose() {
    _controllerSearchChange.close();
    _controllerSearch.dispose();
    super.dispose();
  }

  Future<void> _ensureRuntimeReady() async {
    try {
      await context.modelManage.ensureRuntimeReady();
    } catch (e) {
      loge(e);
    }
  }

  void filterByKeywords(String keywords) {
    _filters = [];
    if (keywords.isEmpty) {
      _showModels = _allModels;
      sortModel();
      return;
    }
    logd('search: $keywords');

    final filtered = _allModels.where(
      (e) =>
          e.name.toLowerCase().contains(keywords) ||
          e.tags.any((t) => t.toLowerCase().contains(keywords)) ||
          e.backend.name.toLowerCase().contains(keywords),
    );
    final selected = filtered.any((e) => e.id == _selectedModelId);
    if (!selected) {
      _selectedModelId = null;
    }
    _showModels = filtered.toList();
    sortModel();
  }

  void filterByFilters(List<String> filters) {
    _controllerSearch.text = '';
    if (filters.isEmpty) {
      _showModels = _allModels;
      sortModel();
      return;
    }
    final filtered = _allModels.where(
      (e) =>
          filters.contains(e.backend.name) ||
          e.tags.any((t) => filters.contains(t)) ||
          e.groups.any((t) => filters.contains(t)),
    );
    final selected = filtered.any((e) => e.id == _selectedModelId);
    if (!selected) {
      _selectedModelId = null;
    }
    _showModels = filtered.toList();
    sortModel();
  }

  void sortModel() {
    _showModels.sort((a, b) {
      final av = a.localPath.isNotEmpty ? 1 : 0;
      final bv = b.localPath.isNotEmpty ? 1 : 0;
      if (a.isRemote) {
        return -1;
      }
      return bv - av;
    });
    if (_sortType != _SortType.download) {
      _showModels.sort((a, b) {
        int s = 0;
        switch (_sortType) {
          case _SortType.modelSize:
            s = -a.modelSize.compareTo(b.modelSize);
          case _SortType.updateAt:
            s = -a.updatedAt.compareTo(b.updatedAt);
          case _SortType.fileSize:
            s = -a.fileSize.compareTo(b.fileSize);
          case _SortType.download:
            s = 0;
        }
        if (s == 0) {
          return -a.name.compareTo(b.name);
        }
        return s;
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = SizedBox(
      width: 200,
      child: TextBox(
        controller: _controllerSearch,
        placeholder: 'name, tag, backend...',
        onChanged: (v) {
          _controllerSearchChange.add(v);
        },
        suffix: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(FluentIcons.search, size: 16),
        ),
      ),
    );

    final listHeaderBar = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SortButton(
          sortType: _sortType,
          onSortTypeChanged: (v) {
            _sortType = v;
            sortModel();
          },
        ),
        _FilterButton(
          filter: _filters,
          onFilterChanged: (f) {
            _filters = f;
            filterByFilters(f);
          },
        ),
        IconButton(
          onPressed: () async {
            await context.modelManage.updateModelList().withToast(
              context,
              success: 'Model list updated',
            );
            filterByFilters(_filters);
            sortModel();
          },
          icon: const Row(
            children: [
              Icon(FluentIcons.refresh),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
      ],
    );

    return Column(
      children: [
        BlocListener<ModelManageCubit, ModelManageState>(
          listenWhen: (p, c) => c.shouldModelListUpdate(p),
          listener: (context, state) {
            _allModels = state.allModels;
            _controllerSearch.text = '';
            _showModels = _allModels;
            sortModel();
          },
          child: const SizedBox(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Models', style: context.typography.subtitle),
              const Spacer(),
              searchBar,
              const SizedBox(width: 16),
              const Divider(direction: Axis.vertical, size: 24),
              const SizedBox(width: 16),
              const _SourceSelector(),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: BlocBuilder<ModelManageCubit, ModelManageState>(
            buildWhen: (p, c) =>
                p.runtimeReady != c.runtimeReady ||
                p.runtimeLoading != c.runtimeLoading ||
                p.runtimeError != c.runtimeError,
            builder: (context, state) {
              if (state.runtimeLoading && !state.runtimeReady) {
                return const Center(child: ProgressRing());
              }
              if (state.runtimeError.isNotEmpty && !state.runtimeReady) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.runtimeError,
                        style: const TextStyle(color: Colors.errorPrimaryColor),
                      ),
                      const SizedBox(height: 12),
                      Button(
                        onPressed: _ensureRuntimeReady,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: LayoutBuilder(
                            builder: (ctx, cs) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: cs.maxWidth),
                                  child: listHeaderBar,
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: ModelList(
                            models: _showModels,
                            selectedModelId: _selectedModelId ?? '',
                            onModelSelected: (model) {
                              setState(() {
                                _selectedModelId = model.id;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(direction: Axis.vertical),
                  Expanded(
                    flex: 5,
                    child: _selectedModelId == null || _selectedModelId!.isEmpty
                        ? Center(
                            child: Text(
                              'No model selected',
                              style: AppTextStyle.bodySecondary,
                            ),
                          )
                        : BlocSelector<ModelManageCubit, ModelManageState, ModelInfo?>(
                            selector: (state) => state.allModels
                                .where((m) => m.id == _selectedModelId)
                                .firstOrNull,
                            builder: (context, state) {
                              if (state == null) {
                                return const SizedBox();
                              }
                              return ModelDetail(model: state);
                            },
                          ),
                  ),
                ],
              );
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
          MenuFlyoutItem(
            text: const Text('Download source'),
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
              text: Text(s == DownloadSource.auto ? 'Auto' : s.name),
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
              Text('Source: ${state == DownloadSource.auto ? 'Auto' : state.name}'),
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
            const Icon(FluentIcons.sort),
            const SizedBox(width: 8),
            Text(sortType.name),
          ],
        ),
        onPressed: _showMenu,
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
      child: IconButton(
        icon: Row(
          children: [
            const Icon(FluentIcons.filter),
            const SizedBox(width: 8),
            Text(filter.isEmpty ? 'No filters' : '${filter.length} filters'),
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
          constraints: const BoxConstraints(maxWidth: 300),
          child: StatefulBuilder(
            builder: (ctx, cs) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Groups',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final g in managerState.getDisplayGroups())
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
                    'Tags',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      for (final tag in managerState.getDisplayTags())
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
                      const Spacer(),
                      Button(
                        child: const Text('Clear'),
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
