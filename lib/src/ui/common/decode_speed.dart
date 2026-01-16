import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/ui/bloc_builders/rwkv_builders.dart';

class DecodeSpeedInfo extends StatelessWidget {
  final String modelInstanceId;

  const DecodeSpeedInfo({super.key, required this.modelInstanceId});

  @override
  Widget build(BuildContext context) {
    return RwkvModelStateBuilder(
      modelInstanceId: modelInstanceId,
      builder: (ctx, model) {
        final decode = model.state.decodeSpeed.toStringAsFixed(2);
        final prefill = model.state.prefillSpeed.toStringAsFixed(2);
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
        if (model.state.prefillProgress < 1.0 &&
            model.state.prefillProgress > 0) {
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
