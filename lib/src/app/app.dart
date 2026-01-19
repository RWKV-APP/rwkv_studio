import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/app/global_providers.dart';
import 'package:rwkv_studio/src/app/router.dart';
import 'package:rwkv_studio/src/app/state_sync_listeners.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/widget/colorful_background.dart';

class RWKVApp extends StatelessWidget {
  const RWKVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return withGlobalBlocProviders(
      BlocSelector<SettingCubit, SettingState, AppearanceSettingState>(
        selector: (state) => state.appearance,
        builder: (context, appearance) {
          final theme = appearance.theme;
          final app = FluentApp(
            title: 'RWKV Studio',
            theme: theme.copyWith(
              navigationPaneTheme: NavigationPaneThemeData(
                backgroundColor: Colors.transparent,
              ),
              typography: Typography.fromBrightness(
                brightness: theme.brightness,
              ).apply(fontFamily: appearance.fontFamily),
              buttonTheme: ButtonThemeData(
                defaultButtonStyle: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  textStyle: theme.buttonTheme.defaultButtonStyle?.textStyle,
                ),
                iconButtonStyle: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                filledButtonStyle: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ),
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
          return Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .max,
            children: [
              Expanded(child: app),
              buildStateSyncListeners(),
            ],
          );
        },
      ),
    );
  }
}
