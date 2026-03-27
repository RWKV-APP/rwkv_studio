part of 'flow_page.dart';

class _AddNodeMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlyoutContent(
      shape: RoundedRectangleBorder(borderRadius: .circular(8)),
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
      child: Column(
        mainAxisSize: .min,
        children: [SizedBox(height: 36, width: 100)],
      ),
    );
  }
}