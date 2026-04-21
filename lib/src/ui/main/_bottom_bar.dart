import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/component_info_dialog.dart';
import 'package:rwkv_studio/src/ui/common/logcat_panel.dart';
import 'package:rwkv_studio/src/utils/string_utils.dart';
import 'package:rwkv_studio/src/widget/app_tooltip.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.fluent.inactiveBackgroundColor,
            width: .5,
          ),
        ),
      ),
      padding: const .symmetric(vertical: 0, horizontal: 4),
      child: ButtonTheme(
        data: const ButtonThemeData(
          iconButtonStyle: ButtonStyle(
            padding: WidgetStatePropertyAll(
              .symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        child: Row(
          children: [
            const Spacer(),
            const AppTooltip(
              message: "application CPU & MEM usage",
              child: _HardwareUsageInfo(),
            ),
            const SizedBox(width: 12),
            const AppTooltip(
              message: "application components",
              child: _ComponentIconButton(),
            ),
            IconButton(
              iconButtonMode: .tiny,
              icon: const Icon(FluentIcons.print),
              onPressed: () => LogcatPanel.attachToRootOverlay(context),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _HardwareUsageInfo extends StatelessWidget {
  const _HardwareUsageInfo();

  @override
  Widget build(BuildContext context) {
    final caption = context.fluent.typography.caption;
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (p, c) => p.hardware != c.hardware,
      builder: (context, state) {
        if (state.hardware == HardwareInfoState.empty) {
          return const SizedBox.shrink();
        }
        Color? textColor;
        if (state.hardware.memUsedPercent > 70 ||
            state.hardware.cpuProcessPercent > 70) {
          textColor = Colors.orange.lighter;
        }
        if (state.hardware.memUsedPercent > 90 ||
            state.hardware.cpuProcessPercent > 90) {
          textColor = Colors.red;
        }

        final cpuApp = state.hardware.cpuProcessPercent.toStringAsFixed(2);
        final memApp = state.hardware.memProcessPercent.toStringAsFixed(2);
        final memUsed = state.hardware.memProcessUsed.formatFileSize;
        return Text(
          "CPU: $cpuApp%   MEM: $memUsed ($memApp%)",
          style: caption?.copyWith(color: textColor, height: 1),
        );
      },
    );
  }
}

class _ComponentIconButton extends StatelessWidget {
  const _ComponentIconButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (p, c) => p.components != c.components,
      builder: (context, state) {
        return IconButton(
          iconButtonMode: .tiny,
          icon: const Icon(FluentIcons.server_processes),
          onPressed: () {
            ComponentInfoDialog.show(context);
          },
        );
      },
    );
  }
}
