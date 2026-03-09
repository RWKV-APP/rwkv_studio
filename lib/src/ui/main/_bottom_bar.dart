import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingCubit, SettingState>(
      buildWhen: (p, c) => p.appearance.userType != c.appearance.userType,
      builder: (context, state) {
        if (state.appearance.userType != UserType.developer) {
          return const SizedBox();
        }
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.fluent.inactiveBackgroundColor),
            ),
          ),
          padding: const .symmetric(vertical: 2, horizontal: 4),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(2)),
                ),
                icon: const Icon(FluentIcons.cat, size: 12),
                onPressed: () {
                  LogcatPanel.attachToRootOverlay(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
