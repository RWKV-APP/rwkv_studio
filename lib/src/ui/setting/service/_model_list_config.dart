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
    return Expander(
      header: Text('模型配置'),
      contentBackgroundColor: context.fluent.cardColor,
      content: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text('配置文件 URL (回车保存)'),
          const SizedBox(height: 8, width: 12),
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
      ),
    );
  }
}
