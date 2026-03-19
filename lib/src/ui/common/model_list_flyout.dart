import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/ui/common/backend_badge.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ModelListFlyout extends StatefulWidget {
  final String? modelInstanceId;
  final Function(ModelInfo info) onModelSelected;
  final bool Function(ModelInfo model)? filter;

  const ModelListFlyout({
    super.key,
    this.modelInstanceId,
    required this.onModelSelected,
    this.filter,
  });

  @override
  State<ModelListFlyout> createState() => _ModelListFlyoutState();
}

class _ModelListFlyoutState extends State<ModelListFlyout> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await context.modelManage.ensureRuntimeReady();
    } catch (e, s) {
      loge(AppException.wrap(e, s));
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  Future<void> _onModelSelected(BuildContext context, ModelInfo info) async {
    if (info.backend == ModelBackend.albatross && !info.isRemote) {
      final py = await context.app.getSelectedPython();
      if (!context.mounted) return;
      if (py == null) {
        showDialog(
          context: context,
          builder: (ctx) => ContentDialog(
            title: const Text('请先设置 Python 环境'),
            content: const Text(
              'Albatross 需要 Python 环境才能运行, 请在设置 -> Python 中设置环境',
            ),
            actions: [
              Button(
                child: const Text('取消'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              FilledButton(
                child: const Text('去设置'),
                onPressed: () {
                  context.app.jump2PythonSettings();
                  Navigator.of(ctx).pop();
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
        return;
      }
    }
    widget.onModelSelected(info);
  }

  Future<void> _onModelReleased(BuildContext context, String instanceId) async {
    await context.llm.release(instanceId).withToast(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      buildWhen: (previous, current) =>
          previous.runtimeLoading != current.runtimeLoading ||
          previous.runtimeError != current.runtimeError ||
          previous.models != current.models ||
          previous.remoteModels != current.remoteModels,
      builder: (context, modelManageState) {
        return BlocBuilder<LlmCubit, LlmState>(
          buildWhen: (previous, current) => previous.models != current.models,
          builder: (context, llmState) {
            return MenuFlyout(
              constraints: const BoxConstraints(minWidth: 300, maxHeight: 600),
              items: _buildItems(
                context: context,
                modelManageState: modelManageState,
                id2instance: llmState.models,
              ),
            );
          },
        );
      },
    );
  }

  List<MenuFlyoutItemBase> _buildItems({
    required BuildContext context,
    required ModelManageState modelManageState,
    required Map<String, ModelInstanceState> id2instance,
  }) {
    final items = <MenuFlyoutItemBase>[];

    if (_initializing || modelManageState.runtimeLoading) {
      items.add(
        MenuFlyoutItem(
          onPressed: null,
          text: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: ProgressRing()),
              SizedBox(width: 8),
              Text('正在初始化...'),
            ],
          ),
        ),
      );
    } else {
      final modelSetting = context.settings.state.model;
      final models =
          [
                ...modelManageState.remoteModels,
                ...modelManageState.models.where(
                  (e) =>
                      e.localPath.isNotEmpty &&
                      e.groups.overlaps({'chat', 'albatross', 'roleplay'}),
                ),
              ]
              .where(
                (e) =>
                    !e.tags.contains('translate') &&
                    (modelSetting.enabledBackends.contains(e.backend) ||
                        e.isRemote),
              )
              .where((e) => widget.filter == null || widget.filter!(e))
              .toList();

      items.addAll(
        _buildModelItems(
          context: context,
          models: models,
          id2instance: id2instance,
        ),
      );

      if (models.isEmpty) {
        items.add(MenuFlyoutItem(text: const Text('没有可用的模型'), onPressed: null));
      }
    }

    if (modelManageState.runtimeError.isNotEmpty) {
      items.add(
        MenuFlyoutItem(
          onPressed: null,
          text: Tooltip(
            message: modelManageState.runtimeError,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.warning, color: Colors.warningPrimaryColor),
                SizedBox(width: 8),
                Text('模型不可以'),
              ],
            ),
          ),
        ),
      );
    }

    items.add(const MenuFlyoutSeparator());

    if (kIsWeb) {
      items.add(
        MenuFlyoutItem(
          text: const Text('模型服务设置'),
          onPressed: () {
            context.app.jump2ModelServiceSettings();
          },
        ),
      );
    }

    if (!kIsWeb) {
      items.add(
        MenuFlyoutItem(
          text: const Text('模型管理'),
          onPressed: () {
            context.app.jump2ModelManage();
          },
        ),
      );
      items.add(
        MenuFlyoutItem(
          text: const Text('导入本地模型'),
          onPressed: () {
            context.toast('请将模型文件拖拽到应用窗口');
          },
        ),
      );
    }

    return items;
  }

  List<MenuFlyoutItemBase> _buildModelItems({
    required BuildContext context,
    required List<ModelInfo> models,
    required Map<String, ModelInstanceState> id2instance,
  }) {
    /// grouping by provider name, if provider name is empty or length <= 2, then flat
    Map<String, List<ModelInfo>> groups = models.groupBy((e) => e.providerName);
    final flat = <ModelInfo>[
      for (final group in groups.entries)
        if (group.key.isEmpty || group.value.length <= 2) ...group.value,
    ];
    groups.removeWhere((k, v) => k.isEmpty || v.length <= 2);
    groups = groups.map((k, v) {
      v.sort((a, b) => a.name.compareTo(b.name));
      return MapEntry(k, v);
    });

    return [
      for (final group in groups.entries)
        MenuFlyoutSubItem(
          text: Text("${group.key} (${group.value.length})"),
          items: (c) {
            return [
              for (final model in group.value)
                _buildMenuItem(
                  context: c,
                  model: model,
                  id2instance: id2instance,
                  showProvider: false,
                ),
            ];
          },
        ),
      for (final model in flat)
        _buildMenuItem(
          context: context,
          model: model,
          id2instance: id2instance,
        ),
    ];
  }

  MenuFlyoutItem _buildMenuItem({
    required BuildContext context,
    required ModelInfo model,
    required Map<String, ModelInstanceState> id2instance,
    bool showProvider = true,
  }) {
    Widget? trailing;
    String name = model.name;
    String tooltips = '';

    final selectedInstance = id2instance[widget.modelInstanceId];
    final inst = id2instance.values
        .where((e) => e.info.id == model.id)
        .firstOrNull;

    if (inst != null && model.localPath.isNotEmpty) {
      trailing = Button(
        onPressed: selectedInstance?.info.id == model.id
            ? null
            : () => _onModelReleased(context, inst.id),
        child: const Text('释放', style: TextStyle(fontSize: 13, height: 1.1)),
      );
    }

    if (model.isRemote) {
      tooltips = '模型来自 ${model.providerName} ${model.providerUrl}'.trim();
      if (showProvider) {
        name = [model.providerName, name].where((e) => e.isNotEmpty).join(': ');
      }
    } else {
      tooltips = model.fileName;
    }

    final backend = model.tags.contains('albatross')
        ? ModelBackend.albatross
        : model.backend;

    Widget? icon;
    bool attachLink = false;

    if (model.isRemote) {
      if (model.backend != ModelBackend.unknown &&
          model.backend.name.isNotEmpty) {
        attachLink = true;
        icon = ModelBackendBadge(backend: backend);
      } else {
        icon = showProvider ? const Icon(FluentIcons.link12) : null;
      }
    } else {
      icon = ModelBackendBadge(backend: backend);
    }

    return ToggleMenuFlyoutItem(
      text: Tooltip(
        message: tooltips,
        child: Row(
          children: [
            ?icon,
            if (icon != null) const SizedBox(width: 8),
            if (attachLink)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(FluentIcons.link12, size: 12),
              ),
            Text(name),
          ],
        ),
      ),
      trailing: trailing,
      value: selectedInstance?.info.id == model.id,
      onChanged: (bool value) {
        if (value) {
          _onModelSelected(context, model);
        }
      },
    );
  }
}
