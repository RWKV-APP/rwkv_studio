import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/models/common/app_component_update.dart';
import 'package:rwkv_studio/src/utils/native_utils.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppComponentInfo current;
  final AppComponentInfo update;

  const AppUpdateDialog({
    super.key,
    required this.current,
    required this.update,
  });

  static Future<void> show(BuildContext context) {
    final update = context.app.state.appUpdate.app;
    final current = context.app.state.appInfo.app;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppUpdateDialog(current: current, update: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500),
      title: Text(current.componentName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: .stretch,
        children: [
          Text("${current.versionName} => ${update.versionName}"),
          const SizedBox(height: 16),
          Text(update.releaseNotes),
          const SizedBox(height: 16),
          Text(
            "更新日期: ${DateTime.fromMillisecondsSinceEpoch(update.timestamp).toIso8601String()}",
          ),
        ],
      ),
      actions: [
        FilledButton(
          child: const Text('去下载'),
          onPressed: () {
            NativeUtils.openUri(update.downloadUrl);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
