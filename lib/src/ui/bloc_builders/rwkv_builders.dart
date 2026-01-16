import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';

typedef StateBuilder =
    Widget Function(BuildContext context, ModelInstanceState model);

class RwkvModelStateBuilder extends StatelessWidget {
  final String modelInstanceId;
  final StateBuilder builder;

  const RwkvModelStateBuilder({
    super.key,
    required this.modelInstanceId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RwkvCubit, RwkvState>(
      key: ValueKey(modelInstanceId),
      buildWhen: (p, c) =>
          p.models[modelInstanceId] != c.models[modelInstanceId],
      builder: (context, state) {
        final model = state.models[modelInstanceId];
        if (model == null) {
          return const SizedBox();
        }
        return builder(context, model);
      },
    );
  }
}
