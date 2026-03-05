part of 'batch_infer_page.dart';

class _ToolBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<BatchInferCubit, BatchInferState>(
          buildWhen: (prev, cur) => cur.performance != prev.performance,
          builder: (context, state) {
            return Row(
              crossAxisAlignment: .end,
              children: [
                Text('并行推理', style: context.fluent.typography.subtitle),
                const SizedBox(width: 16),
                Text(
                  '${state.performance.tps.toInt()} tokens/s',
                  style: const TextStyle(height: 2, fontSize: 10),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 30),
        Expanded(child: _TextBox()),
        const SizedBox(width: 12),
        SizedBox(
          height: 34,
          child: BlocSelector<BatchInferCubit, BatchInferState, ModelLoadState>(
            selector: (state) => state.modelState,
            builder: (context, state) {
              return ModelSelector(
                modelState: state,
                onModelSelected: (s) {
                  context.cubit
                      .loadModel(context, context.rwkv, s)
                      .withToast(context);
                },
                filter: (model) =>
                    model.isRemote || model.backend == ModelBackend.albatross,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocSelector<BatchInferCubit, BatchInferState, BatchSizeState>(
            selector: (state) => state.setting,
            builder: (context, state) {
              return ComboBox(
                onChanged: (v) {
                  if (context.cubit.state.isRunning) {
                    context.toast('请停止推理后修改');
                    return;
                  }
                  context.cubit.setBatchSize(v!);
                },
                items: [
                  for (var v in BatchSizeState.all)
                    ComboBoxItem(
                      value: v,
                      child: Text('${v.size} 路并行 (${v.row}x${v.col})'),
                    ),
                ],
                value: state,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocBuilder<AppCubit, AppState>(
            buildWhen: (prev, cur) => cur.fullScreen != prev.fullScreen,
            builder: (context, state) {
              return Button(
                child: Text(state.fullScreen ? '退出全屏' : '全屏'),
                onPressed: () async {
                  context.app.toggleFullScreen();
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocBuilder<BatchInferCubit, BatchInferState>(
            buildWhen: (prev, cur) =>
                cur.showSettingPanel != prev.showSettingPanel,
            builder: (context, state) {
              return Button(
                child: const Text('解码参数'),
                onPressed: () async {
                  context.cubit.toggleShowSettingPanel();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<BatchInferCubit, BatchInferState>(
            buildWhen: (prev, cur) => cur.textController != prev.textController,
            builder: (context, state) {
              return TextBox(controller: state.textController);
            },
          ),
        ),
        const SizedBox(width: 8),
        BlocBuilder<BatchInferCubit, BatchInferState>(
          buildWhen: (prev, cur) => cur.isRunning != prev.isRunning,
          builder: (context, state) {
            return FilledButton(
              child: state.isRunning
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(strokeWidth: 2),
                        ),
                        SizedBox(width: 4),
                        Text('停止'),
                      ],
                    )
                  : const Text('提交'),
              onPressed: () {
                if (!state.isRunning) {
                  context.cubit.submit(context.rwkv).withToast(context);
                } else {
                  context.cubit.stop();
                }
              },
            );
          },
        ),
      ],
    );
  }
}
