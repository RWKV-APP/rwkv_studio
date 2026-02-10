import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';

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
      header: const Text('外观'),
      content: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              const Text('主题'),
              const SizedBox(width: 12),
              const Spacer(),
              ComboBox<FluentThemeData>(
                items: [
                  ComboBoxItem(
                    value: AppearanceSettingState.lightTheme,
                    child: const Text('Light'),
                  ),
                  ComboBoxItem(
                    value: AppearanceSettingState.darkTheme,
                    child: const Text('Dark'),
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
              const Text('字体'),
              const SizedBox(width: 12),
              const Spacer(),
              ComboBox(
                value: appearance.fontFamily,
                onChanged: (v) {
                  onChanged?.call(appearance.copyWith(fontFamily: v));
                },
                items: [
                  const ComboBoxItem(value: '', child: Text('默认')),
                  const ComboBoxItem(
                    value: 'Microsoft YaHei',
                    child: Text('Microsoft YaHei'),
                  ),
                  const ComboBoxItem(value: '微软雅黑', child: Text('微软雅黑')),
                  const ComboBoxItem(value: '仿宋', child: Text('仿宋')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('字体大小'),
              const SizedBox(width: 12),
              const Spacer(),
              ComboBox(
                value: appearance.fontSize,
                // onChanged: (v) {
                //   onChanged?.call(appearance.copyWith(fontSize: v));
                // },
                onChanged: null,
                items: [
                  const ComboBoxItem(value: 16, child: Text('16')),
                  const ComboBoxItem(value: 18, child: Text('18')),
                  const ComboBoxItem(value: 20, child: Text('20')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('语言'),
              const SizedBox(width: 12),
              const Spacer(),
              ComboBox(
                value: 'zh',
                onChanged: (v) {
                  //
                },
                items: [
                  const ComboBoxItem(value: 'zh', child: Text('简体中文')),
                  // ComboBoxItem(value: 'en', child: Text('English')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('应用模式'),
              const SizedBox(width: 12),
              const Spacer(),
              ComboBox(
                value: appearance.userType,
                onChanged: (v) {
                  onChanged?.call(appearance.copyWith(userType: v));
                },
                items: [
                  const ComboBoxItem(value: UserType.user, child: Text('用户')),
                  const ComboBoxItem(
                    value: UserType.advanced,
                    child: Text('高级'),
                  ),
                  const ComboBoxItem(
                    value: UserType.developer,
                    child: Text('开发者'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
