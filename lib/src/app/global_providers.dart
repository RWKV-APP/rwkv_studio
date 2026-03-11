import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/repository/repositories.dart';

class WithGlobalProviders extends StatelessWidget {
  final Widget child;

  const WithGlobalProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => const ChatRepository()),
        RepositoryProvider(create: (_) => const SettingRepository()),
        RepositoryProvider(create: (_) => const LocalMachineRepository()),
        RepositoryProvider(create: (_) => const RemoteServiceRepository()),
        RepositoryProvider(create: (_) => const DecodeParamRepository()),
        RepositoryProvider(create: (_) => const ModelManagerRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppCubit()),
          BlocProvider(create: (_) => SettingCubit()),
          BlocProvider(create: (_) => ModelManageCubit()),
          BlocProvider(create: (_) => ChatCubit()),
          BlocProvider(create: (_) => RwkvCubit()),
          BlocProvider(create: (_) => TextGenerationCubit()),
          BlocProvider(create: (_) => BatchInferCubit()),
        ],
        child: child,
      ),
    );
  }
}
