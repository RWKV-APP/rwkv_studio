import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/widget/labeled_slider.dart';

class DecodeParamForm extends StatelessWidget {
  final DecodeParam param;
  final ValueChanged<DecodeParam>? onChanged;

  const DecodeParamForm({super.key, required this.param, this.onChanged});

  static Widget createWithBloc({
    required String currentId,
    required bool editable,
  }) {
    return BlocBuilder<LlmCubit, LlmState>(
      buildWhen: (p, c) => p.decodeParams != c.decodeParams,
      builder: (context, state) {
        final param = state.decodeParams[currentId];
        return DecodeParamForm(
          param: param ?? state.decodeParams.values.first,
          onChanged: !editable
              ? null
              : (v) => context.llm.setOrPutDecodeParam(currentId, v),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = const SizedBox(height: 8);
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledSlider(
          title: 'MaxTokens',
          max: 20000,
          min: 50,
          value: param.maxTokens,
          onChanged: (v) {
            onChanged?.call(param.copyWith(maxTokens: v.toInt()));
          },
        ),
        divider,
        LabeledSlider(
          title: 'Temperature',
          value: param.temperature,
          max: 3,
          min: 0,
          divisions: 28,
          onChanged: (v) {
            onChanged?.call(param.copyWith(temperature: v));
          },
        ),
        divider,
        LabeledSlider(
          title: 'TopK',
          max: 128,
          value: param.topK,
          divisions: 128,
          onChanged: (v) {
            onChanged?.call(param.copyWith(topK: v.toInt()));
          },
        ),
        divider,
        LabeledSlider(
          title: 'TopP',
          max: 1,
          value: param.topP,
          divisions: 10,
          onChanged: (v) {
            onChanged?.call(param.copyWith(topP: v));
          },
        ),
        divider,
        LabeledSlider(
          title: 'Presence Penalty',
          value: param.presencePenalty,
          max: 2,
          min: 0,
          divisions: 20,
          onChanged: (v) {
            onChanged?.call(param.copyWith(presencePenalty: v));
          },
        ),
        divider,
        LabeledSlider(
          title: 'Frequency Penalty',
          value: param.frequencyPenalty,
          max: 2,
          min: 0,
          divisions: 20,
          onChanged: (v) {
            onChanged?.call(param.copyWith(frequencyPenalty: v));
          },
        ),
        divider,
        LabeledSlider(
          title: 'Penalty Decay',
          value: param.penaltyDecay,
          max: .999,
          divisions: 10,
          fraction: 3,
          min: .990,
          onChanged: (v) {
            onChanged?.call(param.copyWith(penaltyDecay: v));
          },
        ),
      ],
    );
  }
}
