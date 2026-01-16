import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/ui/common/model_list_flyout.dart';

class ModelSelector extends StatelessWidget {
  final ModelLoadState modelState;
  final Function(ModelInfo modelInfo)? onModelSelected;
  final _itemsController = FlyoutController();

  ModelSelector({super.key, required this.modelState, this.onModelSelected});

  void _showMenu() async {
    _itemsController.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return ModelListFlyout(
          modelInstanceId: modelState.instanceId,
          onModelSelected: (info) => onModelSelected?.call(info),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (modelState.loading) {
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
    if (modelState.error.isNotEmpty) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: modelState.error,
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
      final name = modelState.displayName;
      content = Row(
        children: [
          Icon(WindowsIcons.task_view, size: 14),
          const SizedBox(width: 6),
          Text(name.isNotEmpty ? name : '选择模型', style: TextStyle(fontSize: 13)),
        ],
      );
    }
    return FlyoutTarget(
      controller: _itemsController,
      child: Button(
        onPressed: onModelSelected == null ? null : _showMenu,
        child: Padding(padding: .symmetric(vertical: 1), child: content),
      ),
    );
  }
}
