import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';

typedef ThemeBuilderCallback =
    Widget Function(BuildContext context, FluentThemeData theme);

class ThemeBuilder extends StatelessWidget {
  final ThemeBuilderCallback builder;

  const ThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingCubit, SettingState>(
      buildWhen: (p, c) => p.appearance.theme != c.appearance.theme,
      builder: (context, state) {
        return builder(context, state.appearance.theme);
      },
    );
  }
}


class ThemeListener extends StatelessWidget {
  final Widget child;
  final void Function(FluentThemeData theme) onThemeChanged;

  const ThemeListener({
    super.key,
    required this.child,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.appearance.theme != c.appearance.theme,
      listener: (context, state) {
        onThemeChanged(state.appearance.theme);
      },
      child: child,
    );
  }
}