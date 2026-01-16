import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ModelItemActions extends StatelessWidget {
  final ModelInfo model;
  final bool compact;

  const ModelItemActions({
    super.key,
    required this.model,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              context.modelManage.delete(model.id);
            },
          );
        }

        if (state == null || state.update.state == TaskState.idle) {
          return _buildButton(
            icon: const Icon(WindowsIcons.download),
            primary: true,
            label: '下载',
            onPressed: () {
              context.modelManage.download(model.id);
            },
          );
        }

        final running = state.update.state == TaskState.running;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            if (running) ...[
              if (!state.update.requesting)
                Text(
                  '${state.update.progress.toStringAsFixed(2)}%',
                  style: AppTextTheme.caption,
                ),
              if (!state.update.requesting) const SizedBox(width: 12),
              if (!state.update.requesting)
                Text(
                  '${state.update.speedInMB.toStringAsFixed(2)}MB/s',
                  style: AppTextTheme.caption,
                ),
              const SizedBox(width: 12),
            ],
            const SizedBox(width: 12),
            _buildButton(
              icon: const Icon(WindowsIcons.cancel),
              label: '取消下载',
              onPressed: () {
                context.modelManage.cancel(model.id);
              },
            ),
            const SizedBox(width: 4),
            if (state.update.state == TaskState.running)
              _buildButton(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (state.update.requesting)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: ProgressRing(
                          value: state.update.progress.isNaN
                              ? null
                              : state.update.progress / 100,
                        ),
                      ),
                    const Icon(WindowsIcons.pause),
                  ],
                ),
                label: '暂停',
                onPressed: () {
                  context.modelManage.pause(model.id);
                },
              ),

            if (state.update.state == TaskState.stopped)
              _buildButton(
                icon: const Icon(WindowsIcons.play),
                primary: true,
                label: '继续下载',
                onPressed: () {
                  context.modelManage.resume(model.id);
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
              return Colors.errorPrimaryColor;
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
