import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_interface.dart';
import 'package:rwkv_studio/src/ui/common/model_list_flyout.dart';

typedef ModelFilter = bool Function(ModelInfo model);

class ModelSelector extends StatefulWidget {
  final ModelLoadState modelState;
  final Function(ModelInfo modelInfo)? onModelSelected;
  final ModelFilter? filter;

  const ModelSelector({
    super.key,
    required this.modelState,
    this.onModelSelected,
    this.filter,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  final FlyoutController _itemsController = FlyoutController();

  void _showMenu() {
    _itemsController.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return ModelListFlyout(
          modelInstanceId: widget.modelState.instanceId,
          onModelSelected: (info) => widget.onModelSelected?.call(info),
          filter: widget.filter,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      buildWhen: (p, c) =>
          p.runtimeLoading != c.runtimeLoading ||
          p.runtimeError != c.runtimeError,
      builder: (context, state) {
        if (widget.modelState.loading) {
          return const Button(
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16, height: 16, child: ProgressRing()),
                SizedBox(width: 8),
                Text('加载中...'),
              ],
            ),
          );
        }

        Widget content;
        if (widget.modelState.error.isNotEmpty) {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: widget.modelState.error,
                style: const TooltipThemeData(
                  preferBelow: true,
                  waitDuration: Duration.zero,
                ),
                child: const Icon(
                  FluentIcons.error,
                  color: Colors.errorPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text('加载失败'),
            ],
          );
        } else if (state.runtimeError.isNotEmpty) {
          content = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.warning, color: Colors.warningPrimaryColor),
              SizedBox(width: 8),
              Text('模型不可用'),
            ],
          );
        } else {
          final name = widget.modelState.displayName;
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(WindowsIcons.task_view, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name.isNotEmpty ? name : '请选择模型',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          );
        }

        return FlyoutTarget(
          controller: _itemsController,
          child: Button(
            onPressed: widget.onModelSelected == null ? null : _showMenu,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
