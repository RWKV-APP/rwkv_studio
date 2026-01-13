import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';

class ModelSelector extends StatefulWidget {
  final String? modelInstanceId;
  final Function(ModelInfo? info, ModelInstanceState? model)? onModelSelected;
  final bool load;

  const ModelSelector({
    super.key,
    this.modelInstanceId,
    this.onModelSelected,
    this.load = true,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  final itemsController = FlyoutController();

  void _onModelSelected(ModelInfo model) async {
    ModelInstanceState? modelState = context.rwkvState.models.entries
        .where((e) => e.value.info.id == model.id)
        .firstOrNull
        ?.value;
    if (widget.load) {
      modelState ??= await context.rwkv.loadModel(model);
    }
    if (!mounted) {
      return;
    }
    widget.onModelSelected?.call(model, modelState);
  }

  void _showMenu() async {
    final models = context.modelManage.state.models.where(
      (e) => e.localPath.isNotEmpty,
    );
    ModelInstanceState? modelState = context.rwkvState.models.entries
        .where((e) => e.key == widget.modelInstanceId)
        .firstOrNull
        ?.value;
    itemsController.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return MenuFlyout(
          items: [
            for (final model in models)
              ToggleMenuFlyoutItem(
                text: Text(model.name),
                value: modelState?.info.id == model.id,
                onChanged: (bool value) {
                  if (value) {
                    _onModelSelected(model);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RwkvCubit, RwkvState>(
      buildWhen: (p, c) => p.modelLoadState != c.modelLoadState,
      builder: (context, state) {
        if (state.modelLoadState.loading) {
          return Button(
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16, height: 16, child: ProgressRing()),
                const SizedBox(width: 8),
                Text('加载中...'),
              ],
            ),
          );
        }

        final model = state.models[widget.modelInstanceId];

        return FlyoutTarget(
          controller: itemsController,
          child: Button(
            onPressed: widget.onModelSelected == null ? null : _showMenu,
            child: Text(model?.info.name ?? '选择模型'),
          ),
        );
      },
    );
  }
}
