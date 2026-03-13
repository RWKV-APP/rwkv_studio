import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';

class DecodeSpeedInfo extends StatelessWidget {
  final String modelInstanceId;

  const DecodeSpeedInfo({super.key, required this.modelInstanceId});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RwkvCubit, RwkvState, ModelInstanceState?>(
      selector: (state) => state.models[modelInstanceId],
      builder: (context, model) {
        if (model == null || model.info.isRemote) {
          return const SizedBox();
        }
        final showPrefill =
            model.state.prefillProgress < 1.0 &&
            model.state.prefillProgress > 0;

        final decode = model.state.decodeSpeed.toInt();
        final prefill = model.state.prefillSpeed.toInt();
        final label = Text(
          'prefill: $prefill t/s \t decode: $decode t/s',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.grey[100],
            height: 1,
            fontSize: 12,
          ),
        );
        if (showPrefill) {
          return Row(
            mainAxisAlignment: .end,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: ProgressRing(
                  strokeWidth: 2,
                  value: model.state.prefillProgress * 100,
                ),
              ),
              const SizedBox(width: 8),
              label,
            ],
          );
        }
        return label;
      },
    );
  }
}
