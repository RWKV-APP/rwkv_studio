import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';

class ChatTitleBar extends StatelessWidget {
  const ChatTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.selected != c.selected,
      builder: (context, state) {
        final conv = state.conversations
            .where((c) => c.id == state.selected)
            .firstOrNull;
        if (conv == null) {
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
                buildWhen: (p, c) => p.modelInstanceId != c.modelInstanceId,
                builder: (context, state) {
                  return ModelSelector(
                    modelInstanceId: state.modelInstanceId,
                    autoLoad: true,
                    onModelSelected: (info, instance) {
                      context.chat.onModelSelected(instance!.id);
                    },
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
