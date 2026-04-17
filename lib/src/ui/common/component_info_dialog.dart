import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';

class ComponentInfoDialog extends StatelessWidget {
  const ComponentInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ComponentInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final components = context.app.state.components;

    return ContentDialog(
      title: const Text('Component Info'),
      content: Column(
        mainAxisSize: .min,
        children: [
          for (final component in components)
            ListTile(
              title: Text(component.info.componentName),
              subtitle: Text(component.info.description),
              trailing: Text(
                "${component.info.versionName} -> ${component.latest.versionName}",
              ),
              onPressed: () {
                context.app.downloadComponent(component);
              },
            ),
        ],
      ),
      actions: [
        FilledButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
