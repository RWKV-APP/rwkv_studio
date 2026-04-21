import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/utils/string_utils.dart';

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
              top: BorderSide(
                color: context.fluent.inactiveBackgroundColor,
                width: .5,
              ),
            ),
          ),
          padding: const .symmetric(vertical: 2, horizontal: 4),
          child: Row(
            children: [
              const Spacer(),
              _HardwareUsageInfo(),
              const SizedBox(width: 12),
              IconButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(2)),
                ),
                icon: const Icon(FluentIcons.print, size: 12),
                onPressed: () {
                  LogcatPanel.attachToRootOverlay(context);
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }
}

class _HardwareUsageInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final caption = context.fluent.typography.caption;
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (p, c) => p.hardware != c.hardware,
      builder: (context, state) {
        if (state.hardware == HardwareInfoState.empty) {
          return const SizedBox.shrink();
        }
        final cpuApp = state.hardware.cpuProcessPercent.toStringAsFixed(2);
        final memApp = state.hardware.memProcessPercent.toStringAsFixed(2);
        final memUsed = state.hardware.memProcessUsed.formatFileSize;
        return Text("CPU: $cpuApp%   MEM: $memUsed ($memApp%)", style: caption);
      },
    );
  }
}
