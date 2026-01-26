import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';

class ChatTitleBar extends StatelessWidget {
  const ChatTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.selected != c.selected,
      builder: (context, state) {
        final conv = state.selected;
        if (conv == ConversationState.empty) {
          return SizedBox();
        }
        return Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 100),
                  child: Text(
                    conv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.fluent.typography.bodyLarge,
                  ),
                ),
              ),
              BlocBuilder<ChatCubit, ChatState>(
                buildWhen: (p, c) =>
                    p.modelState != c.modelState ||
                    p.generating != c.generating,
                builder: (context, state) {
                  return ModelSelector(
                    modelState: state.modelState,
                    onModelSelected: state.generating
                        ? null
                        : (s) => context.chat.loadModel(context.rwkv, s),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(FluentIcons.settings),
                onPressed: () {
                  context.chat.toggleSettingPanelVisible();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
