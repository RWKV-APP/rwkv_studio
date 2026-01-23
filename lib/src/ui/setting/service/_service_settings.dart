import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

part '_add_service_button.dart';

part '_model_list_config.dart';

class ServiceSettingCard extends StatelessWidget {
  final ServiceSettingState setting;
  final ValueChanged<ServiceSettingState>? onChanged;

  const ServiceSettingCard({super.key, required this.setting, this.onChanged});

  List<RemoteService> get services => setting.remoteServices;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _ModelListProvider(
          url: setting.modelListUrl,
          onChanged: (v) {
            onChanged?.call(setting.copyWith(modelListUrl: v));
          },
        ),
        const SizedBox(height: 18),
        Text('API 服务', style: theme.typography.subtitle),
        const SizedBox(height: 6),
        Text('支持 OpenAI API 风格接口的模型服务', style: theme.typography.caption),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              _TableHeader(),
              const SizedBox(height: 12),
              Divider(),
              if (services.isEmpty)
                Container(
                  height: 100,
                  alignment: .center,
                  child: IntrinsicHeight(
                    child: _AddButton(
                      onAdd: (v) => onChanged?.call(
                        setting.copyWith(remoteServices: [v, ...services]),
                      ),
                    ),
                  ),
                ),
              for (final service in services)
                _ServiceItem(
                  service: service,
                  setting: setting,
                  onChanged: onChanged,
                ),
              if (services.isNotEmpty)
                _AddButton(
                  onAdd: (v) => onChanged?.call(
                    setting.copyWith(remoteServices: [v, ...services]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text('状态', textAlign: .center)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Text('服务名称')),
        Expanded(flex: 2, child: Text('地址', textAlign: .start)),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: .min,
          children: [
            SizedBox(width: 100, child: Text('启用', textAlign: .center)),
            SizedBox(width: 100, child: Text('操作', textAlign: .center)),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final RemoteService service;
  final ServiceSettingState setting;

  final ValueChanged<ServiceSettingState>? onChanged;

  const _ServiceItem({
    required this.service,
    required this.setting,
    this.onChanged,
  });

  void onTapRemoveService(BuildContext context, RemoteService service) {
    final services = setting.remoteServices;
    onChanged?.call(
      setting.copyWith(
        remoteServices: services.where((e) => e.id != service.id).toList(),
      ),
    );
  }

  void onTapEnableSwitch(BuildContext context, RemoteService service) {
    final services = setting.remoteServices;
    onChanged?.call(
      setting.copyWith(
        remoteServices: services
            .map(
              (e) => e.id == service.id ? e.copyWith(enabled: !e.enabled) : e,
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: service == setting.remoteServices.lastOrNull
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[30])),
            ),
      padding: .symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 50, alignment: .center, child: _ServiceStatus()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(service.name)),
          Expanded(flex: 2, child: Text(service.url, textAlign: .start)),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: .min,
            children: [
              Container(
                width: 100,
                alignment: .center,
                child: ToggleSwitch(
                  checked: service.enabled,
                  onChanged: (v) => onTapEnableSwitch(context, service),
                ),
              ),
              Container(
                width: 100,
                alignment: .center,
                child: IconButton(
                  icon: Row(
                    mainAxisSize: .min,
                    children: [
                      Icon(FluentIcons.delete),
                      const SizedBox(width: 8),
                      Text('删除'),
                    ],
                  ),
                  onPressed: () => onTapRemoveService(context, service),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
