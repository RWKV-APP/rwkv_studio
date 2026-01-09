import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/app/app_cubit.dart';
import 'package:rwkv_studio/src/python/interprater.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

final _lightTheme = FluentThemeData.light();
final _darkTheme = FluentThemeData.dark();

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: theme.typography.title),
          const SizedBox(height: 16),
          Row(children: [Text('Theme'), const SizedBox(width: 16), _theme()]),
          const SizedBox(height: 16),
          Row(children: [Text('Font'), const SizedBox(width: 16), _theme()]),
          const SizedBox(height: 16),
          Button(
            onPressed: () async {
              final path = await PythonInterpreter.getPythonPath();
              logd(path.join('\n'));
            },
            child: Text('Python'),
          ),
        ],
      ),
    );
  }

  Widget _theme() {
    return BlocSelector<AppCubit, AppState, FluentThemeData>(
      selector: (state) => state.theme,
      builder: (context, theme) {
        return ComboBox<FluentThemeData>(
          items: [
            ComboBoxItem(value: _lightTheme, child: Text('Light')),
            ComboBoxItem(value: _darkTheme, child: Text('Dark')),
          ],
          value: theme,
          placeholder: Text(theme == _lightTheme ? 'Light' : 'Dark'),
          onChanged: (value) {
            if (value == _lightTheme) {
              WindowManager.instance.setBrightness(Brightness.light);
            } else {
              WindowManager.instance.setBrightness(Brightness.dark);
            }
            context.app.changeTheme(value!);
          },
        );
      },
    );
  }
}
