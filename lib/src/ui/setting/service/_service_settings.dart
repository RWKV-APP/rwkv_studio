import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

part '_add_service_button.dart';

class ServiceSettingCard extends StatelessWidget {
  final ModelSettingsModel setting;
  final ValueChanged<ModelSettingsModel>? onChanged;

  const ServiceSettingCard({super.key, required this.setting, this.onChanged});

  List<RemoteServiceModel> get services => setting.remoteServices;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expander(
          contentBackgroundColor: context.fluent.cardColor,
          header: const Text('模型服务'),
          contentPadding: const .only(top: 16, bottom: 12),
          trailing: Text(
            '${services.where((e) => e.enabled).length}/${services.length} 已启用',
            style: theme.typography.caption,
          ),
          content: Column(
            crossAxisAlignment: .stretch,
            children: [
              Padding(
                padding: const .only(right: 12, bottom: 16, left: 12),
                child: Text(
                  '支持 OpenAI API 风格接口的模型服务, 添加并启用后, 选择模型列表会出现以 🔗 标记的模型',
                  style: theme.typography.caption,
                ),
              ),
              const SizedBox(height: 6),
              _TableHeader(),
              const SizedBox(height: 12),
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
                Center(
                  child: _AddButton(
                    onAdd: (v) => onChanged?.call(
                      setting.copyWith(remoteServices: [v, ...services]),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (!kIsWeb) const SizedBox(height: 12),
        if (!kIsWeb) _WebUI(),
      ],
    );
  }
}

class _WebUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expander(
      contentBackgroundColor: context.fluent.cardColor,
      header: const Text('WebUI'),
      content: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              const Text('Host:'),
              const SizedBox(width: 5),
              SizedBox(
                width: 150,
                child: TextBox(
                  enabled: false,
                  controller: TextEditingController(text: '0.0.0.0'),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Port:'),
              const SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: TextBox(
                  enabled: false,
                  controller: TextEditingController(text: '8080'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '开启后, RWKV Studio 将提供 WebUI 界面',
            style: context.fluent.typography.caption,
          ),
        ],
      ),
      trailing: ToggleSwitch(
        checked: false,
        onChanged: (v) {
          context.toast('敬请期待');
        },
        leadingContent: true,
        content: const Text('未启用'),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 50, child: Text('状态', textAlign: .center)),
        SizedBox(width: 12),
        Expanded(flex: 2, child: Text('服务名称')),
        Expanded(flex: 2, child: Text('地址', textAlign: .start)),
        Expanded(flex: 2, child: Text('API Key', textAlign: .start)),
        SizedBox(width: 12),
        Row(
          mainAxisSize: .min,
          children: [
            SizedBox(width: 100, child: Text('启用', textAlign: .center)),
            SizedBox(width: 100, child: Text('操作', textAlign: .center)),
          ],
        ),
        SizedBox(width: 12),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final RemoteServiceModel service;
  final ModelSettingsModel setting;

  final ValueChanged<ModelSettingsModel>? onChanged;

  const _ServiceItem({
    required this.service,
    required this.setting,
    this.onChanged,
  });

  void onTapRemoveService(BuildContext context, RemoteServiceModel service) {
    final services = setting.remoteServices;
    onChanged?.call(
      setting.copyWith(
        remoteServices: services.where((e) => e.id != service.id).toList(),
      ),
    );
  }

  void onTapEnableSwitch(BuildContext context, RemoteServiceModel service) {
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.fluent.inactiveBackgroundColor),
        ),
      ),
      padding: const .symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            alignment: .center,
            child: _ServiceStatus(service: service),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(service.name)),
          Expanded(
            flex: 2,
            child: SelectableText(service.url, textAlign: .start),
          ),
          Expanded(
            flex: 2,
            child: Text(
              service.apiKey.isEmpty ? '-' : ('*' * service.apiKey.length),
              maxLines: 1,
              textAlign: .start,
            ),
          ),
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
                  icon: const Row(
                    mainAxisSize: .min,
                    children: [
                      Icon(FluentIcons.delete),
                      SizedBox(width: 8),
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
