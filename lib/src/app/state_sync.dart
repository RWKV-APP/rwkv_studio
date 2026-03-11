import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/app/app_state_coordinator.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class WithGlobalStateSync extends StatefulWidget {
  final Widget child;

  const WithGlobalStateSync({super.key, required this.child});

  @override
  State<WithGlobalStateSync> createState() => _WithGlobalStateSyncState();
}

class _WithGlobalStateSyncState extends State<WithGlobalStateSync> {
  AppStateCoordinator? _coordinator;

  AppStateCoordinator get coordinator =>
      _coordinator ??= AppStateCoordinator.fromContext(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    coordinator;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await coordinator.initialize();
      } catch (e, s) {
        loge(e, s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SettingCubit, SettingState>(
            listenWhen: (p, c) => p != c,
            listener: (context, state) async {
              await coordinator.onSettingStateChanged(state);
            },
          ),
          BlocListener<RwkvCubit, RwkvState>(
            listenWhen: (p, c) => p.models != c.models,
            listener: (context, state) {
              coordinator.onRwkvStateChanged(state);
            },
          ),
        ],
        child: widget.child,
      ),
    );
  }
}
