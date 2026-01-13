import 'package:fluent_ui/fluent_ui.dart';

class LabeledSlider extends StatelessWidget {
  final String title;
  final num value;
  final num min;
  final num max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final int fraction;

  const LabeledSlider({
    super.key,
    required this.title,
    required this.value,
    this.divisions,
    this.fraction = 1,
    this.min = 0,
    this.max = 100,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Text('$title (${value.toStringAsFixed(fraction)})'),
        const SizedBox(height: 6),
        Slider(
          divisions: divisions,
          value: value.toDouble(),
          onChanged: onChanged == null ? null : (v) => onChanged?.call(v),
          min: min.toDouble(),
          max: max.toDouble(),
          label: value.toStringAsFixed(fraction),
        ),
      ],
    );
  }
}
