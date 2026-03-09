import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/setting/_appearance_settings.dart';
import 'package:rwkv_studio/src/ui/setting/_behavior_setting.dart';
import 'package:rwkv_studio/src/ui/setting/service/_model_server_setting.dart';
import 'package:rwkv_studio/src/ui/setting/_model_settings.dart';
import 'package:rwkv_studio/src/ui/setting/_python_settings.dart';
import 'package:rwkv_studio/src/ui/setting/service/_service_settings.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';

part '_cache_settings.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: .infinity,
      width: .infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _SettingBody(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: .start,
      children: [
        Text('设置', style: theme.typography.subtitle),
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
        const SizedBox(height: 12),
        const BehaviorSetting(),
        if (!kIsWeb) const SizedBox(height: 12),
        if (!kIsWeb)
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.cache != c.cache,
            builder: (context, state) {
              return CacheSettingsCard(cache: state.cache);
            },
          ),
        if (!kIsWeb) const SizedBox(height: 12),
        if (!kIsWeb)
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.model != c.model,
            builder: (context, state) {
              return ModelSettings(
                settings: state.model,
                onChanged: (v) {
                  context.settings.setServiceSetting(v);
                },
              );
            },
          ),
        if (!kIsWeb) const SizedBox(height: 12),
        if (!kIsWeb)
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.python != c.python,
            builder: (context, state) {
              return PythonSettings(
                state: state.python,
                onChanged: (v) {
                  context.settings.setPythonSetting(v);
                },
              );
            },
          ),
        const SizedBox(height: 12),

        if (!kIsWeb)
          BlocBuilder<SettingCubit, SettingState>(
            buildWhen: (p, c) => p.model.modelServer != c.model.modelServer,
            builder: (context, state) {
              return ModelServerSettingCard(
                setting: state.model.modelServer,
                onChanged: (v) {
                  context.settings.setServiceSetting(
                    state.model.copyWith(modelServer: v),
                  );
                },
              );
            },
          ),
        if (!kIsWeb) const SizedBox(height: 16),

        BlocBuilder<SettingCubit, SettingState>(
          buildWhen: (p, c) => p.model != c.model,
          builder: (context, state) {
            return ServiceSettingCard(
              setting: state.model,
              onChanged: (v) {
                context.settings.setServiceSetting(v);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          alignment: .bottomCenter,
          height: 600,
          child: Text('RWKV-Studio', style: theme.typography.caption),
        ),
        Center(
          child: HyperlinkButton(
            onPressed: () {
              context.settings.reset();
            },
            child: const Text('重置设置'),
          ),
        ),
      ],
    );
  }
}
