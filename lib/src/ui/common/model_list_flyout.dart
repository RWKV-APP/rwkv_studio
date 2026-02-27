import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/ui/common/backend_badge.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ModelListFlyout extends StatelessWidget {
  final String? modelInstanceId;
  final Function(ModelInfo info) onModelSelected;

  const ModelListFlyout({
    super.key,
    this.modelInstanceId,
    required this.onModelSelected,
  });

  Future _onModelSelected(BuildContext context, ModelInfo info) async {
    if (info.backend == ModelBackend.albatross) {
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
    final modelSetting = context.settings.state.model;
    final availableModels = context.modelManage.availableTextModels.where(
      (e) =>
          !e.tags.contains('translate') &&
          (modelSetting.enabledBackends.contains(e.backend) || e.isRemote),
    );
    final modelIds = availableModels.map((e) => e.id).toList();

    ModelInstanceState? selectedInstance = context.rwkv.getModelInstance(
      modelInstanceId,
    );
    return BlocBuilder<RwkvCubit, RwkvState>(
      buildWhen: (p, c) => p.models != c.models,
      builder: (context, state) {
        final loadedModels = state.models.map((k, v) => MapEntry(v.info.id, v));

        final additional = loadedModels.values.where(
          (e) => !modelIds.contains(e.info.id),
        );

        return MenuFlyout(
          items: [
            for (final model in additional)
              _buildMenuItem(
                context: context,
                model: model.info.toModelInfo(),
                selectedInstance: selectedInstance,
                instanceId: model.id,
                modelSetting: modelSetting,
              ),
            for (final model in availableModels)
              _buildMenuItem(
                context: context,
                model: model,
                selectedInstance: selectedInstance,
                instanceId: loadedModels[model.id]?.id,
                modelSetting: modelSetting,
              ),
            const MenuFlyoutSeparator(),
            MenuFlyoutItem(
              text: const Text('模型管理'),
              onPressed: () {
                context.app.jump2ModelManage();
              },
            ),
            MenuFlyoutItem(
              text: const Text('导入本地模型'),
              onPressed: () {
                context.toast('请将模型文件拖拽到应用窗口');
              },
            ),
          ],
        );
      },
    );
  }

  MenuFlyoutItem _buildMenuItem({
    required BuildContext context,
    required ModelInfo model,
    required ModelInstanceState? selectedInstance,
    required String? instanceId,
    required ModelSettingState modelSetting,
  }) {
    Widget? trailing;
    String name = model.name;
    bool isRemote = model.isRemote;
    String tooltips = '';

    if (instanceId != null && model.localPath.isNotEmpty) {
      trailing = Button(
        onPressed: selectedInstance?.info.id == model.id
            ? null
            : () => _onModelReleased(context, instanceId),
        child: const Text('释放', style: TextStyle(fontSize: 13, height: 1.1)),
      );
    }

    if (isRemote) {
      final s = modelSetting.remoteServices
          .where((e) => e.id == model.serviceId)
          .firstOrNull;
      tooltips =
          '${s?.name ?? model.providerName} 远程模型, instanceId: $instanceId';
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
