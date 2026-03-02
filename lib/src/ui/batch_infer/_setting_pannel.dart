import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_preset_button.dart';

class BatchInferSettingPanel extends StatelessWidget {
  const BatchInferSettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .max,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 12),
            const Expanded(child: Text('设置', style: TextStyle(fontSize: 18))),
            IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: () {
                BatchInferCubit.of(context).toggleShowSettingPanel();
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: BlocBuilder<BatchInferCubit, BatchInferState>(
              buildWhen: (p, c) => p.decodeParamId != c.decodeParamId,
              builder: (context, state) {
                final currentId = state.decodeParamId;
                return Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '解码参数',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DecodeParamPresetButton(
                          currentId: currentId,
                          onChange: (v) {
                            BatchInferCubit.of(context).setDecodeParamId(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DecodeParamForm.createWithBloc(
                      currentId: state.decodeParamId,
                      editable: !state.isRunning,
                    ),
                    const SizedBox(height: 60),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
