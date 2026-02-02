import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';

class PythonSettings extends StatefulWidget {
  final PythonSettingState state;
  final ValueChanged<PythonSettingState> onChanged;

  const PythonSettings({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<PythonSettings> createState() => _PythonSettingsState();
}

class _PythonSettingsState extends State<PythonSettings> {
  String _error = '';
  bool _loading = true;
  List<InterpreterState> _interpreters = [];
  String _selectedType = 'python';
  String _version = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
    });
  }

  void load() async {
    _loading = true;
    setState(() {});
    try {
      final p = await context.app.detectPythonInterpreters();
      _interpreters = p
          .map(
            (e) => InterpreterState(
              id: e.condaEnv?.path ?? e.path,
              path: e.condaEnv?.path ?? e.path,
              name: e.condaEnv?.name ?? '',
              isConda: e.condaEnv != null,
            ),
          )
          .toList();
      final selected = _interpreters
          .where((e) => e.id == widget.state.selected)
          .firstOrNull;

      if (selected == null) {
        if (widget.state.selected.isNotEmpty) {
          widget.onChanged(widget.state.copyWith(selected: ''));
          _version = '';
        }
      } else {
        _selectedType = selected.isConda ? 'conda' : 'python';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: const Text('Python'),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Button(
                onPressed: _loading ? null : load,
                child: const Text('重新加载'),
              ),
              const SizedBox(width: 8),
              if (_loading)
                const SizedBox(width: 20, height: 20, child: ProgressRing()),
              if (!_loading)
                Icon(
                  _error.isNotEmpty
                      ? WindowsIcons.error
                      : WindowsIcons.check_mark,
                  color: _error.isNotEmpty
                      ? Colors.errorPrimaryColor
                      : Colors.green,
                ),
            ],
          ),
          if (_error.isNotEmpty)
            Text(_error, style: TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100),
                child: const Text('类型'),
              ),
              ComboBox(
                value: _selectedType,
                items: [
                  const ComboBoxItem(value: 'python', child: Text('python')),
                  const ComboBoxItem(value: 'conda', child: Text('conda')),
                ],
                onChanged: (v) {
                  widget.onChanged(widget.state.copyWith(selected: ''));
                  setState(() {
                    _version = '';
                    _selectedType = v ?? 'python';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100),
                child: Text(
                  _selectedType == 'python' ? 'Python 路径' : 'Conda 环境',
                ),
              ),
              Expanded(
                child: ComboBox(
                  value: widget.state.selected,
                  isExpanded: true,
                  placeholder: Text(
                    '请选择',
                    style: TextStyle(color: Colors.grey[80]),
                  ),
                  items: [
                    for (final e in _interpreters.where(
                      (e) => (e.isConda ? 'conda' : 'python') == _selectedType,
                    ))
                      ComboBoxItem(value: e.id, child: Text(e.path)),
                  ],
                  onChanged: (v) async {
                    widget.onChanged(widget.state.copyWith(selected: v ?? ''));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
