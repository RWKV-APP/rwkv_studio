import 'package:fluent_ui/fluent_ui.dart';

class AppTooltip extends StatelessWidget {
  final String? message;
  final Widget child;

  const AppTooltip({super.key, this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: message, child: child);
  }
}
