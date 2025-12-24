import 'package:fluent_ui/fluent_ui.dart';

class TapGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const TapGestureDetector({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
