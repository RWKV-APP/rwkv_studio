import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:window_manager/window_manager.dart';

class AppearanceSettings extends StatelessWidget {
  final AppearanceSettingState appearance;
  final ValueChanged<AppearanceSettingState>? onChanged;

  const AppearanceSettings({
    super.key,
    required this.appearance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Text('主题'),
            const SizedBox(width: 12),
            ComboBox<FluentThemeData>(
              items: [
                ComboBoxItem(
                  value: AppearanceSettingState.lightTheme,
                  child: Text('Light'),
                ),
                ComboBoxItem(
                  value: AppearanceSettingState.darkTheme,
                  child: Text('Dark'),
                ),
              ],
              value: appearance.theme,
              placeholder: Text(
                appearance.theme == AppearanceSettingState.lightTheme
                    ? 'Dark'
                    : 'Light',
              ),
              onChanged: (value) {
                final isLight = value == AppearanceSettingState.lightTheme;
                if (isLight) {
                  WindowManager.instance.setBrightness(Brightness.light);
                } else {
                  WindowManager.instance.setBrightness(Brightness.dark);
                }
                Window.setEffect(effect: WindowEffect.mica, dark: !isLight);
                onChanged?.call(appearance.copyWith(theme: value!));
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('字体'),
            const SizedBox(width: 12),
            ComboBox(
              value: appearance.fontFamily,
              onChanged: (v) {
                onChanged?.call(appearance.copyWith(fontFamily: v));
              },
              items: [
                ComboBoxItem(
                  value: 'Microsoft YaHei',
                  child: Text('Microsoft YaHei'),
                ),
                ComboBoxItem(value: '微软雅黑', child: Text('微软雅黑')),
              ],
            ),
            const SizedBox(width: 24),
            Text('字体大小'),
            const SizedBox(width: 12),
            ComboBox(
              value: appearance.fontSize,
              onChanged: (v) {
                onChanged?.call(appearance.copyWith(fontSize: v));
              },
              items: [
                ComboBoxItem(value: 16, child: Text('16')),
                ComboBoxItem(value: 18, child: Text('18')),
                ComboBoxItem(value: 20, child: Text('20')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
