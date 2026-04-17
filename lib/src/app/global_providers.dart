import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/node_flow/node_flow_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/repository/common_repository.dart';
import 'package:rwkv_studio/src/repository/flow_repository.dart';
import 'package:rwkv_studio/src/repository/repositories.dart';

class WithGlobalProviders extends StatelessWidget {
  final Widget child;

  const WithGlobalProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => const ChatRepository()),
        RepositoryProvider(create: (_) => CommonRepository()),
        RepositoryProvider(create: (_) => const NodeFlowRepository()),
        RepositoryProvider(create: (_) => const SettingRepository()),
        RepositoryProvider(create: (_) => LocalMachineRepository()),
        RepositoryProvider(
          create: (_) => McpRepository(),
          dispose: (repository) {
            repository.dispose();
          },
        ),
        RepositoryProvider(
          create: (_) => RemoteServiceRepository(),
          dispose: (repository) {
            repository.dispose();
          },
        ),
        RepositoryProvider(
          create: (context) => LlmSessionRepository(),
          dispose: (repository) {
            repository.dispose();
          },
        ),
        RepositoryProvider(create: (_) => const DecodeParamRepository()),
        RepositoryProvider(
          create: (_) => ModelManagerRepository(),
          dispose: (repository) {
            repository.dispose();
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<NodeFlowBloc>(create: (context) => NodeFlowBloc()),
          BlocProvider(
            create: (context) => AppCubit(
              context.read<LocalMachineRepository>(),
              context.read<RemoteServiceRepository>(),
              context.read<CommonRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                SettingCubit(context.read<SettingRepository>()),
          ),
          BlocProvider(
            create: (context) => ModelManageCubit(
              context.read<ModelManagerRepository>(),
              context.read<RemoteServiceRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ChatCubit(
              context.read<ChatRepository>(),
              context.read<LlmSessionRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => LlmCubit(
              context.read<DecodeParamRepository>(),
              context.read<LlmSessionRepository>(),
              context.read<McpRepository>(),
            ),
          ),
          BlocProvider(create: (_) => TextGenerationCubit()),
          BlocProvider(create: (_) => BatchInferCubit()),
        ],
        child: child,
      ),
    );
  }
}
