part of '_service_settings.dart';

class _AddButton extends StatefulWidget {
  final ValueChanged<RemoteService>? onAdd;

  const _AddButton({this.onAdd});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isAdding = false;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController(text: 'http://127.0.0.1:8000');

  bool _enabled = true;

  void onTapAddService() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      return;
    }
    _nameController.clear();
    _urlController.clear();
    setState(() {
      _isAdding = false;
    });
    widget.onAdd?.call(
      RemoteService(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        enabled: _enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Row(
        crossAxisAlignment: .center,
        children: [
          SizedBox(
            width: 50,
            child: Center(child: Icon(WindowsIcons.edit, size: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Padding(
              padding: .only(right: 16),
              child: TextBox(
                controller: _nameController,
                placeholder: '请输入服务名称',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextBox(
              controller: _urlController,
              placeholder: '请输入服务地址',
              onSubmitted: (v) {
                onTapAddService();
              },
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: .min,
            children: [
              Container(
                width: 100,
                alignment: .center,
                child: ToggleSwitch(
                  checked: _enabled,
                  onChanged: (v) {
                    setState(() {
                      _enabled = v;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    IconButton(
                      onPressed: () {
                        _nameController.clear();
                        _urlController.clear();
                        _isAdding = false;
                        setState(() {});
                      },
                      icon: Icon(FluentIcons.cancel),
                    ),
                    IconButton(
                      onPressed: onTapAddService,
                      icon: Icon(FluentIcons.check_mark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      );
    }
    return IconButton(
      icon: Row(
        mainAxisSize: .min,
        children: [
          Icon(FluentIcons.add),
          const SizedBox(width: 8),
          Text('添加服务'),
        ],
      ),
      onPressed: () {
        setState(() {
          _isAdding = true;
        });
      },
    );
  }
}

class _ServiceStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(WindowsIcons.status_circle_question_mark);
    return Icon(WindowsIcons.network_connected_checkmark, color: Colors.green);
  }
}
