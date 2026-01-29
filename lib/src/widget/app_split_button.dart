import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class AppSplitButton extends StatelessWidget {
  final bool checked;
  final VoidCallback onInvoked;
  final Widget flyout;
  final Widget child;

  AppSplitButton.toggle({
    super.key,
    required this.checked,
    required this.onInvoked,
    required this.flyout,
    required this.child,
  });

  final controller = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final theme = context.fluent;
    return ToggleButton(
      checked: checked,
      onChanged: (v) => onInvoked(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            child,
            Divider(
              direction: .vertical,
              style: DividerThemeData(
                verticalMargin: .zero,
                decoration: !checked
                    ? null
                    : BoxDecoration(color: theme.activeColor),
              ),
            ),
            GestureDetector(
              onTap: () {
                controller.showFlyout(builder: (ctx) => flyout);
              },
              behavior: .translucent,
              child: FlyoutTarget(
                controller: controller,
                child: const Padding(
                  padding: .symmetric(horizontal: 2),
                  child: Icon(WindowsIcons.chevron_down, size: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
