import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
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
    return BlocBuilder<RwkvCubit, RwkvState>(
      builder: (context, state) {
        final localModels = context.modelManage.localModels;
        ModelInstanceState? selectedInstance = context.rwkv.getModelInstance(
          modelInstanceId,
        );
        final loadedModels = context.rwkvState.models.map(
          (k, v) => MapEntry(v.info.id, v),
        );
        return MenuFlyout(
          items: [
            for (final model in localModels)
              ToggleMenuFlyoutItem(
                text: Row(
                  children: [
                    Text(model.name),
                    const SizedBox(width: 4),
                    ModelBackendBadge(info: model),
                  ],
                ),
                trailing: loadedModels.containsKey(model.id)
                    ? Button(
                        onPressed: selectedInstance?.info.id == model.id
                            ? null
                            : () {
                                context.rwkv
                                    .release(loadedModels[model.id]!.id)
                                    .withToast(context);
                              },
                        child: Text('释放'),
                      )
                    : null,
                value: selectedInstance?.info.id == model.id,
                onChanged: (bool value) {
                  if (value) {
                    onModelSelected(model);
                  }
                },
              ),
            MenuFlyoutSeparator(),
            MenuFlyoutItem(text: const Text('模型管理'), onPressed: () {}),
            MenuFlyoutItem(text: const Text('导入本地模型'), onPressed: () {}),
          ],
        );
      },
    );
  }
}
