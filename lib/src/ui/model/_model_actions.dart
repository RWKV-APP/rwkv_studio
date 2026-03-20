import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ModelItemActions extends StatelessWidget {
  final ModelInfo model;
  final bool compact;

  const ModelItemActions({
    super.key,
    required this.model,
    required this.compact,
  });

  @override
  Widget build(BuildContext ctx) {
    return BlocSelector<
      ModelManageCubit,
      ModelManageState,
      ModelDownloadState?
    >(
      selector: (state) => state.modelStates[model.id],
      builder: (context, state) {
        if (model.localPath.isNotEmpty || state?.update.progress == 100) {
          return _buildButton(
            icon: const Icon(WindowsIcons.delete),
            label: '删除',
            danger: true,
            onPressed: () async {
              await context.modelManage.delete(model.id).withToast(ctx);
            },
          );
        }

        if (state == null || state.update.state == TaskState.idle) {
          return _buildButton(
            icon: const Icon(WindowsIcons.download),
            primary: true,
            label: '下载',
            onPressed: () async {
              await context.modelManage.download(model.id).withToast(ctx);
            },
          );
        }

        final running = state.update.state == TaskState.running;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            if (running) ...[
              if (state.update.requesting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: ProgressRing(strokeWidth: 2),
                ),
              if (!state.update.requesting)
                Text(
                  '${state.update.progress.toStringAsFixed(2)}%',
                  style: AppTextStyle.caption,
                ),
              if (!state.update.requesting) const SizedBox(width: 12),
              if (!state.update.requesting)
                Text(
                  '${state.update.speedInMB.toStringAsFixed(2)}MB/s',
                  style: AppTextStyle.caption,
                ),
              const SizedBox(width: 12),
            ],
            const SizedBox(width: 12),
            _buildButton(
              icon: const Icon(WindowsIcons.cancel),
              label: '取消下载',
              onPressed: () async {
                await context.modelManage.cancel(model.id).withToast(context);
              },
            ),
            const SizedBox(width: 4),
            if (running)
              _buildButton(
                icon: const Icon(WindowsIcons.pause),
                label: '暂停',
                onPressed: () async {
                  await context.modelManage.pause(model.id).withToast(context);
                },
              ),

            if (state.update.state == TaskState.stopped)
              _buildButton(
                icon: const Icon(WindowsIcons.play),
                primary: true,
                label: '继续下载',
                onPressed: () async {
                  await context.modelManage.resume(model.id).withToast(context);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required Widget icon,
    required VoidCallback onPressed,
    String? label,
    bool danger = false,
    bool primary = false,
  }) {
    if (!compact) {
      final child = Row(
        children: [icon, const SizedBox(width: 8), Text(label ?? '')],
      );

      if (danger) {
        return Button(
          onPressed: onPressed,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return Colors.red.light;
            }),
          ),
          child: child,
        );
      }

      if (!primary) {
        return Button(onPressed: onPressed, child: child);
      }
      return FilledButton(onPressed: onPressed, child: child);
    }
    return IconButton(icon: icon, onPressed: onPressed);
  }
}
