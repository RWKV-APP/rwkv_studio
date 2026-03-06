import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/settings/model_server_state.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ModelServerSettingCard extends StatefulWidget {
  final ModelServerSetting setting;
  final ValueChanged<ModelServerSetting> onChanged;

  const ModelServerSettingCard({
    super.key,
    required this.setting,
    required this.onChanged,
  });

  @override
  State<ModelServerSettingCard> createState() => _ModelServerSettingCardState();
}

class _ModelServerSettingCardState extends State<ModelServerSettingCard> {
  late final _controllerHost = TextEditingController(text: widget.setting.host);
  late final _controllerPort = TextEditingController(
    text: widget.setting.port.toString(),
  );

  late bool _enabled = widget.setting.enabled;

  @override
  Widget build(BuildContext context) {
    final fluent = context.fluent;
    return Expander(
      contentBackgroundColor: fluent.cardColor,
      header: const Text('作为模型服务'),
      contentPadding: const .only(top: 16, bottom: 16, right: 12, left: 12),
      trailing: Text(
        widget.setting.enabled ? '已启用' : '已停用',
        style: fluent.typography.caption,
      ),
      content: Column(
        crossAxisAlignment: .start,
        children: [
          ToggleSwitch(
            checked: _enabled,
            onChanged: (v) {
              setState(() {
                _enabled = v;
              });
            },
            leadingContent: true,
            content: const Text('是否启用服务'),
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: .center,
            children: [
              const Text('Host:'),
              const SizedBox(width: 5),
              SizedBox(width: 150, child: TextBox(controller: _controllerHost)),
              const SizedBox(width: 12),
              const Text('Port:'),
              const SizedBox(width: 5),
              SizedBox(width: 100, child: TextBox(controller: _controllerPort)),
              const SizedBox(width: 12),
              FilledButton(
                child: const Text('保存'),
                onPressed: () {
                  widget.onChanged(
                    widget.setting.copyWith(
                      host: _controllerHost.text,
                      port: int.tryParse(_controllerPort.text),
                      enabled: _enabled,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '开启后, RWKV Studio 将提供 OpenAI 风格的 API 接口访问服务\n v1/models\nv1/chat/completions',
            style: context.fluent.typography.caption,
          ),
        ],
      ),
    );
  }
}
