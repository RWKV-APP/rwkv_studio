import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/common/model_list_flyout.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ModelSelector extends StatefulWidget {
  final String? modelInstanceId;
  final Function(ModelInfo? info, ModelInstanceState? model)? onModelSelected;
  final bool autoLoad;

  const ModelSelector({
    super.key,
    this.modelInstanceId,
    this.onModelSelected,
    this.autoLoad = true,
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
    if (widget.autoLoad) {
      modelState ??= await context.rwkv.loadModel(model).withToast(context);
    }
    if (!mounted || widget.onModelSelected == null) {
      return;
    }
    context.rwkv.clearLoadState();
    widget.onModelSelected?.call(model, modelState);
  }

  void _showMenu() async {
    itemsController.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return ModelListFlyout(
          modelInstanceId: widget.modelInstanceId,
          onModelSelected: (info) => _onModelSelected(info),
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

        Widget content;
        if (state.modelLoadState.error.isNotEmpty) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: state.modelLoadState.error,
                style: const TooltipThemeData(
                  preferBelow: true,
                  waitDuration: Duration.zero,
                ),
                child: Icon(FluentIcons.error, color: Colors.errorPrimaryColor),
              ),
              const SizedBox(width: 8),
              Text('加载失败'),
            ],
          );
        } else {
          final model = state.models[widget.modelInstanceId];
          content = Text(model?.info.name ?? '选择模型');
        }
        return FlyoutTarget(
          controller: itemsController,
          child: Button(
            onPressed: widget.onModelSelected == null ? null : _showMenu,
            child: content,
          ),
        );
      },
    );
  }
}
