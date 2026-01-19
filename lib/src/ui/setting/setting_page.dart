import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/setting/_appearance_settings.dart';
import 'package:rwkv_studio/src/ui/setting/_service_settings.dart';

part '_cache_settings.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('设置', style: theme.typography.title),
          const SizedBox(height: 24),
          Text('外观', style: theme.typography.subtitle),
          const SizedBox(height: 16),
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.appearance != c.appearance,
            builder: (context, state) {
              return AppearanceSettings(
                appearance: state.appearance,
                onChanged: (v) {
                  context.settings.setAppearance(v);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text('缓存', style: theme.typography.subtitle),
          const SizedBox(height: 16),
          CacheSettingsCard(),
          const SizedBox(height: 24),
          Text('服务', style: theme.typography.subtitle),
          const SizedBox(height: 16),
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.remoteServices != c.remoteServices,
            builder: (context, state) {
              return ServiceSettingCard(
                services: state.remoteServices,
                onChanged: (v) {
                  context.settings.setRemoteServiceList(v);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          Container(
            alignment: .bottomCenter,
            height: 100,
            child: Text('RWKV-Studio', style: theme.typography.caption),
          ),
        ],
      ),
    );
  }
}
