part of 'main_page.dart';

class _DownloadTaskFlyout extends StatelessWidget {
  const _DownloadTaskFlyout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      builder: (context, state) {
        return BlocBuilder<AppCubit, AppState>(
          buildWhen: (p, c) => p.downloadTasks != c.downloadTasks,
          builder: (context, appState) {
            return _buildContent(context, state, appState.downloadTasks);
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ModelManageState state,
    List<DownloadTaskInfo> appDownloads,
  ) {
    final id2model = {for (final model in state.models) model.id: model};

    return FlyoutContent(
      padding: const .only(top: 12, bottom: 16, left: 12, right: 12),
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('下载任务', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final entry in appDownloads)
            _buildTaskItem(
              context,
              entry.name,
              entry.status,
              onPauseTap: () {
                context.app.pauseTask(entry.id).withToast(context);
              },
              onCancelTap: () {
                context.app.cancelTask(entry.id).withToast(context);
              },
              onResumeTap: () {
                context.app.resumeTask(entry.id).withToast(context);
              },
            ),
          for (final entry in state.modelStates.entries)
            _buildTaskItem(
              context,
              id2model[entry.key]!.name,
              entry.value?.update,
              onCancelTap: () async {
                await context.modelManage.cancel(entry.key).withToast(context);
              },
              onPauseTap: () async {
                await context.modelManage.pause(entry.key).withToast(context);
              },
              onResumeTap: () async {
                await context.modelManage.resume(entry.key).withToast(context);
              },
            ),
          if (state.modelStates.isEmpty && appDownloads.isEmpty)
            Center(
              heightFactor: 4,
              child: Text('没有下载任务', style: TextStyle(color: Colors.grey[80])),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    String name,
    TaskUpdate? state, {
    required VoidCallback onPauseTap,
    required VoidCallback onCancelTap,
    required VoidCallback onResumeTap,
  }) {
    if (state == null) {
      return const SizedBox();
    }
    return Container(
      margin: const .only(top: 4),
      decoration: BoxDecoration(
        borderRadius: .circular(6),
        color: context.fluent.cardColor,
      ),
      clipBehavior: .antiAlias,
      child: LayoutBuilder(
        builder: (ctx, cs) {
          final p = state.progress.isNaN ? 0 : state.progress.clamp(0, 100);
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                width: cs.maxWidth * (p / 100),
                bottom: 0,
                child: Container(
                  height: 12,
                  color: Colors.green.withAlpha(100),
                ),
              ),
              Padding(
                padding: const .symmetric(vertical: 4, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: .ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),

                    if (state.isRunning && !state.requesting)
                      Padding(
                        padding: const .symmetric(horizontal: 12),
                        child: Text(
                          '${state.speedInMB.toStringAsFixed(2)}MB/s',
                          style: AppTextStyle.caption,
                        ),
                      ),

                    IconButton(
                      icon: const Icon(WindowsIcons.cancel),
                      onPressed: onCancelTap,
                    ),

                    if (state.isRunning && !state.requesting)
                      IconButton(
                        icon: const Icon(WindowsIcons.pause),
                        onPressed: onPauseTap,
                      ),

                    if (state.isRunning && state.requesting)
                      Container(
                        padding: state.requesting
                            ? const .symmetric(horizontal: 5)
                            : null,
                        width: 30,
                        height: 20,
                        child: ProgressRing(
                          strokeWidth: 3,
                          value: state.progress.isNaN
                              ? null
                              : state.progress / 100,
                        ),
                      ),

                    if (state.isStopped)
                      IconButton(
                        icon: const Icon(WindowsIcons.play),
                        onPressed: onResumeTap,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DownloadInfoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      buildWhen: (p, c) => p.modelStates != c.modelStates,
      builder: (context, modelState) {
        return BlocBuilder<AppCubit, AppState>(
          buildWhen: (p, c) => p.downloadTasks != c.downloadTasks,
          builder: (context, appState) {
            final total =
                modelState.modelStates.length + appState.downloadTasks.length;
            if (total == 0) {
              return const SizedBox();
            }
            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.red.lighter,
              ),
              alignment: Alignment.center,
              child: Text(
                total.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  height: 1,
                  fontSize: 10,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
