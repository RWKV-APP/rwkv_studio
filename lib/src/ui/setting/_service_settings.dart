import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';

class ServiceSettingCard extends StatelessWidget {
  final List<RemoteService> services;
  final ValueChanged<List<RemoteService>>? onChanged;

  const ServiceSettingCard({super.key, required this.services, this.onChanged});

  void onTapRemoveService(BuildContext context, RemoteService service) {
    onChanged?.call(services.where((e) => e.id != service.id).toList());
  }

  void onTapEnableSwitch(BuildContext context, RemoteService service) {
    onChanged?.call(
      services
          .map((e) => e.id == service.id ? e.copyWith(enabled: !e.enabled) : e)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 50, child: Text('状态', textAlign: .center)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: Text('服务名称')),
              Expanded(flex: 2, child: Text('地址', textAlign: .start)),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: .min,
                children: [
                  SizedBox(width: 100, child: Text('启用', textAlign: .center)),
                  SizedBox(width: 100, child: Text('操作', textAlign: .center)),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 12),
          Divider(),
          if (services.isEmpty)
            Container(
              height: 100,
              alignment: .center,
              child: IntrinsicHeight(
                child: _AddButton(
                  onAdd: (v) => onChanged?.call([v, ...services]),
                ),
              ),
            ),
          for (final service in services)
            Container(
              decoration: service == services.lastOrNull
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[30]),
                      ),
                    ),
              padding: .symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    alignment: .center,
                    child: _ServiceStatus(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: Text(service.name)),
                  Expanded(
                    flex: 2,
                    child: Text(service.url, textAlign: .start),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: .min,
                    children: [
                      Container(
                        width: 100,
                        alignment: .center,
                        child: ToggleSwitch(
                          checked: service.enabled,
                          onChanged: (v) => onTapEnableSwitch(context, service),
                        ),
                      ),
                      Container(
                        width: 100,
                        alignment: .center,
                        child: IconButton(
                          icon: Row(
                            mainAxisSize: .min,
                            children: [
                              Icon(FluentIcons.delete),
                              const SizedBox(width: 8),
                              Text('删除'),
                            ],
                          ),
                          onPressed: () => onTapRemoveService(context, service),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),
                ],
              ),
            ),

          if (services.isNotEmpty)
            _AddButton(onAdd: (v) => onChanged?.call([v, ...services])),
        ],
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final ValueChanged<RemoteService>? onAdd;

  const _AddButton({this.onAdd});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isAdding = false;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

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
          SizedBox(width: 50),
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
            child: TextBox(controller: _urlController, placeholder: '请输入服务地址'),
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
    return Icon(WindowsIcons.network_connected_checkmark, color: Colors.green);
  }
}
