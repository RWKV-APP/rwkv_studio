import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';

class ModelBackendBadge extends StatelessWidget {
  final ModelBackend backend;

  const ModelBackendBadge({super.key, required this.backend});

  @override
  Widget build(BuildContext context) {
    Widget icon =
        _getIcon() ??
        Text(
          backend.name,
          overflow: TextOverflow.clip,
          maxLines: 1,
          textAlign: .center,
          style: const TextStyle(color: Colors.white, fontSize: 8, height: 1),
        );
    return Tooltip(
      message: backend.name,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.teal.lightest,
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
    if (backend == ModelBackend.albatross) {
      return ColoredBox(
        color: Colors.grey[60],
        child: Image.asset(
          'assets/img/icon_albatross.png',
          fit: BoxFit.contain,
        ),
      );
    } else if (backend == ModelBackend.llama_cpp) {
      return Image.asset('assets/img/icon_llama_cpp.png', fit: BoxFit.contain);
    } else if (backend == ModelBackend.pytorch) {
      return Container(
        height: 20,
        width: 20,
        color: Colors.black,
        child: Image.asset('assets/img/icon_pytorch.png', fit: BoxFit.contain),
      );
    } else if (backend == ModelBackend.web_rwkv) {
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
            const Text(
              'R',
              style: TextStyle(color: Colors.black, fontSize: 10),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
