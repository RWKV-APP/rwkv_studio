import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ModelBackendBadge extends StatelessWidget {
  final ModelInfo info;

  const ModelBackendBadge({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    String label = info.backend.name;
    if (label == ModelBackend.albatross.name ||
        info.tags.contains('albatross')) {
      label = '🕊️';
    } else if (label == ModelBackend.llama_cpp.name) {
      label = '🦙';
    }
    return Tooltip(
      message: info.backend.name,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: context.fluent.accentColor.lightest,
        ),
        child: Text(
          label,
          style: context.typography.caption?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
