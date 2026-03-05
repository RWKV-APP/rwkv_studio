part of 'batch_infer_page.dart';

class _TitleBar extends StatelessWidget {
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
        const Expanded(child: _PromptInputBox()),
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

class _PromptInputBox extends StatefulWidget {
  const _PromptInputBox();

  @override
  State<_PromptInputBox> createState() => _PromptInputBoxState();
}

class _PromptInputBoxState extends State<_PromptInputBox> {
  final FlyoutController _editorController = FlyoutController();
  final FocusNode _inputFocusNode = FocusNode();
  final GlobalKey _inputAnchorKey = GlobalKey();

  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_onInputFocusChanged);
  }

  @override
  void dispose() {
    _inputFocusNode.removeListener(_onInputFocusChanged);
    _inputFocusNode.dispose();
    _editorController.dispose();
    super.dispose();
  }

  void _onInputFocusChanged() {
    if (!_inputFocusNode.hasFocus) {
      return;
    }
    _inputFocusNode.unfocus();
    _showEditorFlyout();
  }

  Future<void> _showEditorFlyout() async {
    if (!mounted || _openingEditor || _editorController.isOpen) {
      return;
    }
    _openingEditor = true;

    final sourceController = context.cubit.state.textController;
    final editController = TextEditingController(text: sourceController.text)
      ..selection = TextSelection.collapsed(
        offset: sourceController.text.length,
      );
    final anchorWidth = _resolveAnchorWidth();
    final anchorPosition = _resolveAnchorPosition();

    String? result;
    try {
      result = await _editorController.showFlyout<String?>(
        position: anchorPosition,
        placementMode: FlyoutPlacementMode.bottomLeft,
        autoModeConfiguration: FlyoutAutoConfiguration(
          preferredMode: FlyoutPlacementMode.bottomLeft,
        ),
        additionalOffset: 0,
        barrierDismissible: true,
        dismissOnPointerMoveAway: false,
        dismissWithEsc: true,
        builder: (ctx) {
          return FlyoutContent(
            child: SizedBox(
              width: anchorWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextBox(
                    controller: editController,
                    autofocus: true,
                    minLines: 6,
                    maxLines: 10,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      Button(
                        child: const Text('取消'),
                        onPressed: () {
                          Flyout.of(ctx).close();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        child: const Text('确定'),
                        onPressed: () {
                          context.cubit.submit(context.rwkv).withToast(context);
                          _editorController.close(editController.text);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      editController.dispose();
      _openingEditor = false;
    }

    if (!mounted || result == null) {
      return;
    }

    sourceController.value = sourceController.value.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
      composing: TextRange.empty,
    );
  }

  double _resolveAnchorWidth() {
    final anchorContext = _inputAnchorKey.currentContext;
    if (anchorContext == null) {
      return 520;
    }
    final renderObject = anchorContext.findRenderObject();
    if (renderObject is! RenderBox) {
      return 520;
    }
    return renderObject.size.width.clamp(320.0, 900.0).toDouble();
  }

  Offset? _resolveAnchorPosition() {
    final anchorContext = _inputAnchorKey.currentContext;
    if (anchorContext == null) {
      return null;
    }
    final targetRenderObject = anchorContext.findRenderObject();
    final navigatorRenderObject = Navigator.of(
      context,
    ).context.findRenderObject();
    if (targetRenderObject is! RenderBox ||
        navigatorRenderObject is! RenderBox) {
      return null;
    }
    return targetRenderObject.localToGlobal(
      Offset.zero,
      ancestor: navigatorRenderObject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _editorController,
      child: BlocBuilder<BatchInferCubit, BatchInferState>(
        buildWhen: (prev, cur) => cur.textController != prev.textController,
        builder: (context, state) {
          return SizedBox(
            key: _inputAnchorKey,
            child: TextBox(
              controller: state.textController,
              focusNode: _inputFocusNode,
              readOnly: true,
              maxLines: 1,
            ),
          );
        },
      ),
    );
  }
}
