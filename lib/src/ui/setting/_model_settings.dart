import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/backend_badge.dart';

class ModelSettings extends StatelessWidget {
  final ServiceSettingState settings;
  final ValueChanged<ServiceSettingState>? onChanged;

  ModelSettings({super.key, required this.settings, this.onChanged});

  late final _controller = TextEditingController(text: settings.modelListUrl);

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: const Text('模型设置'),
      contentBackgroundColor: context.fluent.cardColor,
      content: Column(
        crossAxisAlignment: .stretch,
        children: [
          const Text('模型列表配置文件 URL (回车保存)'),
          const SizedBox(height: 8, width: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: TextBox(
              controller: _controller,
              onSubmitted: (v) {
                onChanged?.call(settings.copyWith(modelListUrl: v));
              },
            ),
          ),
          const SizedBox(height: 18, width: 12),
          const Text('启用模型后端'),
          const SizedBox(height: 12, width: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final backend in ModelBackend.defaultBackends.where(
                (e) => e.platforms.contains(ModelPlatform.current),
              ))
                Checkbox(
                  checked: settings.enabledBackends.contains(backend),
                  onChanged: (v) {
                    if (v == true) {
                      onChanged?.call(
                        settings.copyWith(
                          enabledBackends: [
                            ...settings.enabledBackends,
                            backend,
                          ],
                        ),
                      );
                    } else {
                      onChanged?.call(
                        settings.copyWith(
                          enabledBackends: settings.enabledBackends
                              .where((e) => e != backend)
                              .toList(),
                        ),
                      );
                    }
                  },
                  content: Row(
                    children: [
                      ModelBackendBadge(backend: backend),
                      const SizedBox(width: 8),
                      Text(backend.displayName),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
