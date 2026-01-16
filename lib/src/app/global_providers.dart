import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';

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
