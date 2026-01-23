part of '_service_settings.dart';

class _ModelListProvider extends StatefulWidget {
  final String url;
  final ValueChanged<String>? onChanged;

  const _ModelListProvider({required this.url, this.onChanged});

  @override
  State<_ModelListProvider> createState() => _ModelListProviderState();
}

class _ModelListProviderState extends State<_ModelListProvider> {
  late final _controller = TextEditingController(text: widget.url);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text('模型列表配置 (回车保存)'),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: TextBox(
            controller: _controller,
            onSubmitted: (v) {
              widget.onChanged?.call(v);
            },
          ),
        ),
      ],
    );
  }
}
