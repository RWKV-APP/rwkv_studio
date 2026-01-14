import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/app/app_cubit.dart';
import 'package:rwkv_studio/src/python/interprater.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

part '_cache_settings.dart';

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
          Text('设置', style: theme.typography.title),
          const SizedBox(height: 16),
          Text('外观', style: theme.typography.subtitle),
          const SizedBox(height: 16),
          Row(children: [Text('主题'), const SizedBox(width: 16), _theme()]),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('字体'),
              const SizedBox(width: 12),
              ComboBox(
                value: 'Microsoft YaHei',
                onChanged: (v) {
                  //
                },
                items: [
                  ComboBoxItem(
                    value: 'Microsoft YaHei',
                    child: Text('Microsoft YaHei'),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Text('字体大小'),
              const SizedBox(width: 12),
              ComboBox(
                value: '16',
                onChanged: (v) {
                  //
                },
                items: [
                  ComboBoxItem(value: '16', child: Text('16')),
                  ComboBoxItem(value: '18', child: Text('18')),
                  ComboBoxItem(value: '20', child: Text('20')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CacheSettingsCard(),
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
          placeholder: Text(theme == _lightTheme ? 'Dark' : 'Light'),
          onChanged: (value) {
            if (value == _lightTheme) {
              WindowManager.instance.setBrightness(Brightness.light);
            } else {
              WindowManager.instance.setBrightness(Brightness.dark);
            }
            Window.setEffect(
              effect: WindowEffect.mica,
              dark: value == _darkTheme,
            );
            context.app.changeTheme(value!);
          },
        );
      },
    );
  }
}
