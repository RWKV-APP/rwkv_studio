import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';

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
    return Expander(
      header: Text('外观'),
      content: Column(
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
                  ComboBoxItem(value: '', child: Text('默认')),
                  ComboBoxItem(
                    value: 'Microsoft YaHei',
                    child: Text('Microsoft YaHei'),
                  ),
                  ComboBoxItem(value: '微软雅黑', child: Text('微软雅黑')),
                  ComboBoxItem(value: '仿宋', child: Text('仿宋')),
                ],
              ),
              const SizedBox(width: 24),
              Text('字体大小'),
              const SizedBox(width: 12),
              ComboBox(
                value: appearance.fontSize,
                // onChanged: (v) {
                //   onChanged?.call(appearance.copyWith(fontSize: v));
                // },
                onChanged: null,
                items: [
                  ComboBoxItem(value: 16, child: Text('16')),
                  ComboBoxItem(value: 18, child: Text('18')),
                  ComboBoxItem(value: 20, child: Text('20')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('语言'),
              const SizedBox(width: 12),
              ComboBox(
                value: 'zh',
                onChanged: null,
                items: [
                  ComboBoxItem(value: 'zh', child: Text('简体中文')),
                  ComboBoxItem(value: 'en', child: Text('English')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('应用模式'),
              const SizedBox(width: 12),
              ComboBox(
                value: 'dev',
                onChanged: null,
                items: [
                  ComboBoxItem(value: 'dev', child: Text('开发者')),
                  ComboBoxItem(value: 'expert', child: Text('专家')),
                  ComboBoxItem(value: 'user', child: Text('用户')),
                  ComboBoxItem(value: 'basic', child: Text('基础')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
