part of 'text_generation_page.dart';

class _TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextGenerationCubit, TextGenerationState>(
      buildWhen: (p, c) =>
          p.modelState != c.modelState || p.generating != c.generating,
      builder: (context, state) {
        return Row(
          children: [
            Text('文本生成', style: context.fluent.typography.bodyLarge),
            const Spacer(),
            Button(
              onPressed: state.generating
                  ? null
                  : () async {
                      await context.cubit
                          .generate(context.rwkv, fim: true)
                          .withToast(context);
                    },
              child: const Text('FIM'),
            ),
            const SizedBox(width: 8),
            ModelSelector(
              modelState: state.modelState,
              onModelSelected: state.generating
                  ? null
                  : (model) {
                      context.cubit.loadModel(context, context.rwkv, model);
                    },
              filter: (model) => !model.name.toLowerCase().contains('neko'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state.modelInstanceId.isEmpty
                  ? null
                  : () async {
                      if (state.generating) {
                        context.cubit.stop(context.rwkv);
                      } else {
                        await context.cubit
                            .generate(context.rwkv)
                            .withToast(context);
                      }
                    },
              child: Row(
                children: [
                  Icon(
                    state.generating ? WindowsIcons.pause : WindowsIcons.play,
                  ),
                  const SizedBox(width: 8),
                  Text(state.generating ? '停止生成' : '开始生成'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(FluentIcons.settings),
              onPressed: () {
                context.cubit.toggleSettingPane();
              },
            ),
          ],
        );
      },
    );
  }
}
