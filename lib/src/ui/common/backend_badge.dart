import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ModelBackendBadge extends StatelessWidget {
  final ModelInfo info;

  const ModelBackendBadge({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: context.fluent.accentColor.lightest,
      ),
      child: Text(
        info.backend.name,
        style: context.typography.caption?.copyWith(color: Colors.white),
      ),
    );
  }
}
