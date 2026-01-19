import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

Widget buildStateSyncListeners() {
  return Column(
    mainAxisSize: .min,
    children: [
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.remoteServices != c.remoteServices,
        listener: (context, state) {
          final services = state.remoteServices.where((e) => e.enabled);
          final providers = services
              .map(
                (e) => RemoteModelProviderInfo(
                  name: e.name,
                  url: "${e.url}/status",
                  serviceId: e.id,
                ),
              )
              .toList();
          context.modelManage.setModelProviders(providers);
          context.rwkv.setRemoteServiceList({
            for (final service in services) service.id: service.url,
          });
        },
        child: SizedBox(),
      ),
      BlocListener<ModelManageCubit, ModelManageState>(
        listenWhen: (p, c) => p.models != c.models,
        listener: (context, state) {
          logd(
            'model-list changed: ${state.models.length} models, '
            '${state.availableModels.length} available',
          );
        },
        child: SizedBox(),
      ),

      BlocListener<RwkvCubit, RwkvState>(
        listenWhen: (p, c) => p.models != c.models,
        listener: (context, state) {
          logd('model-instance changed: ${state.models.length} instances');
          final chat = context.chat.state.modelInstanceId;
          final textGen = context.textGen.state.modelInstanceId;
          if (chat.isNotEmpty && state.models[chat] == null) {
            context.chat.onModelReleased();
          }
          if (textGen.isNotEmpty && state.models[textGen] == null) {
            context.textGen.onModelReleased();
          }
        },
        child: SizedBox(),
      ),
    ],
  );
}
