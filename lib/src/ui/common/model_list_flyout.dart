import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    final availableModels = context.modelManage.availableModels;
    ModelInstanceState? selectedInstance = context.rwkv.getModelInstance(
      modelInstanceId,
    );
    return BlocBuilder<RwkvCubit, RwkvState>(
      buildWhen: (p, c) => p.models != c.models,
      builder: (context, state) {
        final loadedModels = state.models.map((k, v) => MapEntry(v.info.id, v));
        return MenuFlyout(
          items: [
            for (final model in availableModels)
              _buildMenuItem(
                context: context,
                model: model,
                selectedInstance: selectedInstance,
                instanceId: loadedModels[model.id]?.id,
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
                //
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
  }) {
    Widget? trailing;
    String name = model.name;
    bool isRemote = model.isRemote;
    String tooltips = '';

    if (instanceId != null && model.localPath.isNotEmpty) {
      trailing = Button(
        onPressed: selectedInstance?.info.id == model.id
            ? null
            : () {
                context.rwkv.release(instanceId).withToast(context);
              },
        child: const Text('释放', style: TextStyle(fontSize: 13, height: 1.1)),
      );
    }

    if (isRemote) {
      name = "🔗$name";
      tooltips = '${model.providerName} 远程模型, instanceId: $instanceId';
    } else {
      tooltips = model.fileName;
    }

    return ToggleMenuFlyoutItem(
      text: Tooltip(
        message: tooltips,
        child: Row(
          children: [
            ModelBackendBadge(info: model),
            const SizedBox(width: 8),
            Text(name),
          ],
        ),
      ),
      trailing: trailing,
      value: selectedInstance?.info.id == model.id,
      onChanged: (bool value) {
        if (value) {
          onModelSelected(model);
        }
      },
    );
  }
}
