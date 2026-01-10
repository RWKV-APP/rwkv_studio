import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/app/router.dart';
import 'package:rwkv_studio/src/global/app/app_cubit.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_cubit.dart';

class RWKVApp extends StatelessWidget {
  const RWKVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ModelManageCubit()),
        BlocProvider(create: (_) => ChatCubit()),
        BlocProvider(create: (_) => AppCubit()),
        BlocProvider(create: (_) => RwkvCubit()),
        BlocProvider(create: (_) => TextGenerationCubit()),
      ],
      child: BlocSelector<AppCubit, AppState, FluentThemeData>(
        selector: (state) => state.theme,
        builder: (context, theme) {
          return FluentApp(
            title: 'RWKV Studio',
            theme: theme.copyWith(
              typography: Typography.fromBrightness(
                brightness: theme.brightness,
              ).apply(fontFamily: 'NotoSansSC'),
              buttonTheme: ButtonThemeData(
                defaultButtonStyle: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          );
        },
      ),
    );
  }
}
