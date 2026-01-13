import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/app/app_cubit.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/global/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_cubit.dart';

Widget withGlobalBlocProviders(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ModelManageCubit()),
      BlocProvider(create: (_) => ChatCubit()),
      BlocProvider(create: (_) => AppCubit()),
      BlocProvider(create: (_) => RwkvCubit()),
      BlocProvider(create: (_) => TextGenerationCubit()),
    ],
    child: child,
  );
}
