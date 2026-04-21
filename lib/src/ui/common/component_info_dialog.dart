import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/models/common/download_task_info.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/path.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ComponentInfoDialog extends StatelessWidget {
  const ComponentInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ComponentInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final components = state.components;
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 500),
          title: const Text('组件信息'),
          content: Column(
            mainAxisSize: .min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (components.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('暂无组件信息'),
                ),
              for (final component in components.values)
                _buildComponentTile(context, state, component),
            ],
          ),
          actions: [
            FilledButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  static Widget _buildComponentTile(
    BuildContext context,
    AppState state,
    AppComponent component,
  ) {
    final task = _findDownloadTask(state.downloadTasks, component);
    return _ComponentItem(component: component, task: task);
  }

  static DownloadTaskInfo? _findDownloadTask(
    List<DownloadTaskInfo> tasks,
    AppComponent component,
  ) {
    final latest = component.latest;
    if (latest.downloadUrl.isEmpty) {
      return null;
    }
    final name =
        '${latest.componentName}_${latest.versionName}_${latest.versionCode}.zip';
    final path = appDataDir.childFile(name).absolute.path;
    return tasks
        .where(
          (task) =>
              task.type == DownloadTaskType.component &&
              task.url == latest.downloadUrl &&
              task.name == name &&
              task.path == path,
        )
        .firstOrNull;
  }
}

class _ComponentItem extends StatelessWidget {
  final AppComponent component;
  final DownloadTaskInfo? task;

  const _ComponentItem({required this.component, this.task});

  @override
  Widget build(BuildContext context) {
    final theme = context.fluent;

    final downloading = task?.status.isRunning == true;
    final progress = task?.status.progress ?? double.nan;
    final showInstall = component.hasUpdate && task?.status.isCompleted == true;
    final showDownload = !downloading && !showInstall && component.missing;
    final showUpdate =
        !downloading && !showInstall && !showDownload && component.hasUpdate;

    final upgradeText = (showUpdate || showInstall)
        ? '->${component.latest.versionName}'
        : '';

    return Container(
      margin: const .only(top: 8),
      padding: const .symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: .circular(8),
        border: .all(color: Colors.grey[40]),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            "${component.info.componentName} (${component.info.versionName}$upgradeText)",
            style: theme.typography.bodyLarge?.copyWith(fontWeight: .w600),
          ),
          const SizedBox(height: 6),
          Text(component.info.description),
          if (downloading)
            Align(
              alignment: .centerRight,
              child: FilledButton(
                child: Text(
                  '下载中 ${progress.isNaN ? '...' : progress.toStringAsFixed(2)}%',
                ),
                onPressed: () {
                  context.app.pauseTask(task!.id);
                },
              ),
            ),
          if (showDownload)
            Align(
              alignment: .centerRight,
              child: FilledButton(
                child: const Text('下载'),
                onPressed: () {
                  context.app.downloadComponent(component).withToast(context);
                },
              ),
            ),
          if (showUpdate)
            Align(
              alignment: .centerRight,
              child: FilledButton(
                child: const Text('更新'),
                onPressed: () {
                  context.app.updateComponent(component).withToast(context);
                },
              ),
            ),
          if (showInstall)
            Align(
              alignment: .centerRight,
              child: FilledButton(
                child: const Text('安装'),
                onPressed: () {
                  context.app
                      .installComponentUpdate(component)
                      .withToast(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}
