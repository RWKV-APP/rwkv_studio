import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/app/global_providers.dart';
import 'package:rwkv_studio/src/app/router.dart';
import 'package:rwkv_studio/src/app/state_sync.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/theme/fluent.dart';
import 'package:rwkv_studio/src/widget/colorful_background.dart';

class RWKVApp extends StatelessWidget {
  const RWKVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithGlobalProviders(
      child: BlocBuilder<SettingCubit, SettingState>(
        buildWhen: (p, c) =>
            p.appearance != c.appearance || p.initialized != c.initialized,
        builder: (context, state) {
          final appearance = state.appearance;
          final theme = appearance.theme.custom(
            fontFamily: appearance.fontFamily,
          );
          final app = FluentApp(
            title: 'RWKV Studio',
            theme: theme,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRouter.initialRoute,
            routes: AppRouter.routes,
            builder: (ctx, child) {
              if (kIsWeb) {
                return RandomMicaBackground(
                  seed: 1,
                  brightness: theme.brightness,
                  blobCount: 12,
                  fogBlurSigma: 15,
                  tintAlpha: 60,
                  noiseOpacity: 0.2,
                  child: child,
                );
              }
              return child ?? SizedBox();
            },
          );
          return WithGlobalStateSync(child: app);
        },
      ),
    );
  }
}
