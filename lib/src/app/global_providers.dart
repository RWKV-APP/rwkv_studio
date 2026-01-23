import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';

class WithGlobalProviders extends StatelessWidget {
  final Widget child;

  const WithGlobalProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingCubit()),
        BlocProvider(create: (_) => ModelManageCubit()),
        BlocProvider(create: (_) => ChatCubit()),
        BlocProvider(create: (_) => RwkvCubit()),
        BlocProvider(create: (_) => TextGenerationCubit()),
      ],
      child: child,
    );
  }
}
