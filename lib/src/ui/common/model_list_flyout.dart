import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/common/backend_badge.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ModelListFlyout extends StatelessWidget {
  final String? modelInstanceId;
  final Function(ModelInfo info) onModelSelected;

  final List<ModelInfo> models;
  final Map<String, ModelInstanceState> id2instance;

  const ModelListFlyout({
    super.key,
    this.modelInstanceId,
    required this.onModelSelected,
    required this.models,
    required this.id2instance,
  });

  Future _onModelSelected(BuildContext context, ModelInfo info) async {
    if (info.backend == ModelBackend.albatross && !info.isRemote) {
      if (context.app.getSelectedPython() == null) {
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
    onModelSelected(info);
  }

  Future _onModelReleased(BuildContext context, String instanceId) async {
    context.rwkv.release(instanceId).withToast(context);
  }

  @override
  Widget build(BuildContext context) {
    return MenuFlyout(
      items: [
        for (final model in models)
          _buildMenuItem(context: context, model: model),
        if (models.isEmpty)
          MenuFlyoutItem(text: const Text('没有可用的模型'), onPressed: null),
        const MenuFlyoutSeparator(),
        if (kIsWeb)
          MenuFlyoutItem(
            text: const Text('模型服务设置'),
            onPressed: () {
              context.app.jump2ModelServiceSettings();
            },
          ),
        if (!kIsWeb)
          MenuFlyoutItem(
            text: const Text('模型管理'),
            onPressed: () {
              context.app.jump2ModelManage();
            },
          ),
        if (!kIsWeb)
          MenuFlyoutItem(
            text: const Text('导入本地模型'),
            onPressed: () {
              context.toast('请将模型文件拖拽到应用窗口');
            },
          ),
      ],
    );
  }

  MenuFlyoutItem _buildMenuItem({
    required BuildContext context,
    required ModelInfo model,
  }) {
    Widget? trailing;
    String name = model.name;
    String tooltips = '';

    final selectedInstance = id2instance[modelInstanceId];

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
      name = [model.providerName, name].where((e) => e.isNotEmpty).join(': ');
    } else {
      tooltips = model.fileName;
    }

    final backend = model.tags.contains('albatross')
        ? ModelBackend.albatross
        : model.backend;

    Widget icon;

    bool attachLink = false;

    if (model.isRemote) {
      if (model.backend != ModelBackend.unknown) {
        attachLink = true;
        icon = ModelBackendBadge(backend: backend);
      } else {
        icon = const Icon(FluentIcons.link12);
      }
    } else {
      icon = ModelBackendBadge(backend: backend);
    }

    return ToggleMenuFlyoutItem(
      text: Tooltip(
        message: tooltips,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            if (attachLink)
              const Padding(
                padding: .only(right: 4),
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
