part of 'main_page.dart';

class _DownloadTaskFlyout extends StatelessWidget {
  const _DownloadTaskFlyout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModelManageCubit, ModelManageState>(
      builder: (context, state) {
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
              for (final entry in state.modelStates.entries)
                _buildTaskItem(context, entry.value, id2model[entry.key]),
              if (state.modelStates.isEmpty)
                Center(
                  heightFactor: 4,
                  child: Text(
                    '没有下载任务',
                    style: TextStyle(color: Colors.grey[80]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    ModelDownloadState? state,
    ModelInfo? model,
  ) {
    if (state == null || model == null) {
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
          final p = state.update.progress.isNaN
              ? 0
              : state.update.progress.clamp(0, 100);
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
                        model.name,
                        overflow: .ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),

                    if (state.update.isRunning && !state.update.requesting)
                      Padding(
                        padding: const .symmetric(horizontal: 12),
                        child: Text(
                          '${state.update.speedInMB.toStringAsFixed(2)}MB/s',
                          style: AppTextStyle.caption,
                        ),
                      ),

                    IconButton(
                      icon: const Icon(WindowsIcons.cancel),
                      onPressed: () async {
                        await context.modelManage
                            .cancel(model.id)
                            .withToast(context);
                      },
                    ),

                    if (state.update.isRunning && !state.update.requesting)
                      IconButton(
                        icon: const Icon(WindowsIcons.pause),
                        onPressed: () async {
                          await context.modelManage
                              .pause(model.id)
                              .withToast(context);
                        },
                      ),

                    if (state.update.isRunning && state.update.requesting)
                      Container(
                        padding: state.update.requesting
                            ? const .symmetric(horizontal: 5)
                            : null,
                        width: 30,
                        height: 20,
                        child: ProgressRing(
                          strokeWidth: 3,
                          value: state.update.progress.isNaN
                              ? null
                              : state.update.progress / 100,
                        ),
                      ),

                    if (state.update.isStopped)
                      IconButton(
                        icon: const Icon(WindowsIcons.play),
                        onPressed: () async {
                          await context.modelManage
                              .resume(model.id)
                              .withToast(context);
                        },
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
      builder: (context, state) {
        if (state.modelStates.isEmpty) {
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
            state.modelStates.length.toString(),
            style: const TextStyle(
              color: Colors.white,
              height: 1,
              fontSize: 10,
            ),
          ),
        );
      },
    );
  }
}
