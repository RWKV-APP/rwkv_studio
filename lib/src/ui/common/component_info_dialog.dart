import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/models/common/download_task_info.dart';
import 'package:rwkv_studio/src/utils/native_utils.dart';
import 'package:rwkv_studio/src/utils/path.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ComponentInfoDialog extends StatelessWidget {
  const ComponentInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ComponentInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final currentApp = state.appInfo.app;
        final latestApp = state.appUpdate.app;
        final hasAppUpdate = latestApp.versionCode > currentApp.versionCode;
        final components = state.components;

        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 500),
          title: const Text('组件信息'),
          content: Column(
            mainAxisSize: .min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('App'),
              _InfoTile(
                title: currentApp.componentName.isNotEmpty
                    ? currentApp.componentName
                    : 'RWKV Studio',
                description: _firstNotEmpty(
                  currentApp.description,
                  latestApp.description,
                ),
                currentVersion: currentApp.versionName,
                latestVersion: latestApp.versionName,
                statusText: hasAppUpdate ? '状态: 可更新' : '状态: 已是最新版本',
                taskStatusText: null,
                actionLabel: hasAppUpdate ? '更新' : null,
                onUpdate: !hasAppUpdate || latestApp.downloadUrl.isEmpty
                    ? null
                    : () async {
                        await NativeUtils.openUri(
                          latestApp.downloadUrl,
                        ).withToast(context);
                      },
              ),
              const SizedBox(height: 12),
              const Text('Components'),
              if (components.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('暂无组件信息'),
                ),
              for (final component in components)
                _buildComponentTile(context, state, component),
            ],
          ),
          actions: [
            FilledButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  static String _firstNotEmpty(String first, [String? second, String? third]) {
    if (first.isNotEmpty) {
      return first;
    }
    if (second != null && second.isNotEmpty) {
      return second;
    }
    if (third != null && third.isNotEmpty) {
      return third;
    }
    return '-';
  }

  static Widget _buildComponentTile(
    BuildContext context,
    AppState state,
    AppComponent component,
  ) {
    final task = _findDownloadTask(state.downloadTasks, component);
    final actionLabel = _componentActionLabel(component, task);
    final canDownload =
        component.latest.downloadUrl.isNotEmpty &&
        (task == null || task.status.isStopped || task.status.isIdle);

    return _InfoTile(
      title: _firstNotEmpty(
        component.info.componentName,
        component.latest.componentName,
        component.type.name,
      ),
      description: _firstNotEmpty(
        component.info.description,
        component.latest.description,
      ),
      currentVersion: component.info.versionName,
      latestVersion: component.latest.versionName,
      statusText: _componentStatusText(component),
      taskStatusText: task == null
          ? null
          : _downloadTaskStatusText(task.status),
      actionLabel: actionLabel,
      onUpdate: !canDownload
          ? null
          : () async {
              await context.app
                  .downloadComponent(component)
                  .withToast(
                    context,
                    success: task == null
                        ? '已开始下载'
                        : (task.status.isStopped || task.status.isIdle)
                        ? '已继续下载'
                        : null,
                  );
            },
    );
  }

  static String _componentStatusText(AppComponent component) {
    if (component.missing) {
      return '状态: 缺失组件';
    }
    if (component.hasUpdate) {
      return '状态: 可更新';
    }
    return '状态: 已安装';
  }

  static String? _componentActionLabel(
    AppComponent component,
    DownloadTaskInfo? task,
  ) {
    if (task != null) {
      if (task.status.isCompleted) {
        return '已下载';
      }
      if (task.status.isRunning) {
        return '下载中';
      }
      if (task.status.isStopped || task.status.isIdle) {
        return '继续下载';
      }
    }
    if (component.missing) {
      return '下载';
    }
    if (component.hasUpdate) {
      return '更新';
    }
    return null;
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

  static String _downloadTaskStatusText(TaskUpdate status) {
    if (status.isCompleted) {
      return '下载任务: 已完成';
    }
    if (status.isRunning) {
      if (status.requesting) {
        return '下载任务: 连接中';
      }
      return '下载任务: 下载中 ${status.progress.toStringAsFixed(1)}% (${status.speedInMB.toStringAsFixed(2)}MB/s)';
    }
    if (status.isStopped) {
      if (status.progress.isNaN) {
        return '下载任务: 已暂停';
      }
      return '下载任务: 已暂停 ${status.progress.toStringAsFixed(1)}%';
    }
    return '下载任务: 等待开始';
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String description;
  final String currentVersion;
  final String latestVersion;
  final String statusText;
  final String? taskStatusText;
  final String? actionLabel;
  final Future<void> Function()? onUpdate;

  const _InfoTile({
    required this.title,
    required this.description,
    required this.currentVersion,
    required this.latestVersion,
    required this.statusText,
    required this.taskStatusText,
    required this.actionLabel,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (description.isNotEmpty && description != '-') description,
      statusText,
      '当前版本: ${currentVersion.isEmpty ? '-' : currentVersion}',
      '最新版本: ${latestVersion.isEmpty ? '-' : latestVersion}',
      if (taskStatusText != null) taskStatusText!,
    ].join('\n');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(details),
        trailing: actionLabel != null
            ? FilledButton(
                onPressed: onUpdate == null
                    ? null
                    : () async {
                        await onUpdate!();
                      },
                child: Text(actionLabel!),
              )
            : null,
      ),
    );
  }
}
