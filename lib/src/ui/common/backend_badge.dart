import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ModelBackendBadge extends StatelessWidget {
  final ModelInfo info;

  const ModelBackendBadge({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    Widget icon =
        _getIcon() ??
        Text(
          info.backend.name,
          overflow: TextOverflow.clip,
          maxLines: 1,
          textAlign: .center,
          style: TextStyle(color: Colors.white, fontSize: 10, height: 1),
        );
    return Tooltip(
      message: info.backend.name,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: context.fluent.accentColor.lightest,
        ),
        height: 20,
        width: 20,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }

  Widget? _getIcon() {
    if (info.backend == ModelBackend.albatross ||
        info.tags.contains('albatross')) {
      return ColoredBox(
        color: Colors.grey[60],
        child: Image.asset(
          'assets/img/icon_albatross.png',
          fit: BoxFit.contain,
        ),
      );
    } else if (info.backend == ModelBackend.llama_cpp) {
      return Image.asset('assets/img/icon_llama_cpp.png', fit: BoxFit.contain);
    } else if (info.backend == ModelBackend.web_rwkv) {
      return Container(
        height: 20,
        width: 20,
        color: Colors.grey[20],
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Text(
              'W',
              style: TextStyle(color: Colors.blue.lightest, fontSize: 10),
            ),
            Text('R', style: TextStyle(color: Colors.black, fontSize: 10)),
          ],
        ),
      );
    }
    return null;
  }
}
