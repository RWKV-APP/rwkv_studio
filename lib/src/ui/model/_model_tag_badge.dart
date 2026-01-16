import 'package:fluent_ui/fluent_ui.dart';

class ModelTagBadge extends StatelessWidget {
  final String tag;

  const ModelTagBadge({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final display =
        {"reason": "推理", "batch": "并行", "albatross": "Albatross"}[tag] ??
        tag.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(display),
    );
  }
}
