part of 'mcp_page.dart';

class _McpServerDialog extends StatefulWidget {
  final McpServerModel? initial;

  const _McpServerDialog({this.initial});

  static Future<McpServerModel?> show(
    BuildContext context, {
    McpServerModel? initial,
  }) {
    return showDialog<McpServerModel>(
      context: context,
      builder: (context) => _McpServerDialog(initial: initial),
    );
  }

  @override
  State<_McpServerDialog> createState() => _McpServerDialogState();
}

class _McpServerDialogState extends State<_McpServerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _argsController;
  late final TextEditingController _workingDirectoryController;
  late final TextEditingController _environmentController;
  late final TextEditingController _urlController;
  late final TextEditingController _headersController;
  late final TextEditingController _timeoutController;

  late McpTransportType _transportType;
  late bool _enabled;
  late bool _includeParentEnvironment;
  late bool _openEventStream;
  late bool _deleteSessionOnClose;

  bool _testing = false;

  McpServerModel get _baseServer => widget.initial ?? McpServerModel.empty();

  @override
  void initState() {
    super.initState();
    final server = _baseServer;
    _nameController = TextEditingController(text: server.name);
    _commandController = TextEditingController(text: server.command);
    _argsController = TextEditingController(text: server.args.join('\n'));
    _workingDirectoryController = TextEditingController(
      text: server.workingDirectory,
    );
    _environmentController = TextEditingController(
      text: _formatMap(server.environment),
    );
    _urlController = TextEditingController(text: server.url);
    _headersController = TextEditingController(
      text: _formatMap(server.headers),
    );
    _timeoutController = TextEditingController(
      text: server.requestTimeoutMs.toString(),
    );
    _transportType = server.transportType;
    _enabled = server.enabled;
    _includeParentEnvironment = server.includeParentEnvironment;
    _openEventStream = server.openEventStream;
    _deleteSessionOnClose = server.deleteSessionOnClose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _workingDirectoryController.dispose();
    _environmentController.dispose();
    _urlController.dispose();
    _headersController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  Future<void> _onTest() async {
    setState(() {
      _testing = true;
    });

    try {
      final server = _buildServer(validate: true);
      final success = await context
          .read<McpRepository>()
          .testConnection(server)
          .withLoading(context)
          .withToast(context);
      if (mounted) {
        context.toast(
          success ? 'Connection test succeeded' : 'Connection test failed',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  void _onSave() {
    try {
      final server = _buildServer(validate: true);
      Navigator.of(context).pop(server);
    } catch (e) {
      context.toast(AppException.wrap(e).displayMessage);
    }
  }

  McpServerModel _buildServer({required bool validate}) {
    final timeout = int.tryParse(_timeoutController.text.trim()) ?? 30000;
    final server = _baseServer.copyWith(
      id: _baseServer.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : _baseServer.id,
      name: _nameController.text.trim(),
      enabled: _enabled,
      transportType: _transportType,
      command: _commandController.text.trim(),
      args: _parseLines(_argsController.text),
      workingDirectory: _workingDirectoryController.text.trim(),
      environment: _parseMap(_environmentController.text),
      includeParentEnvironment: _includeParentEnvironment,
      url: _urlController.text.trim(),
      headers: _parseMap(_headersController.text),
      requestTimeoutMs: timeout.clamp(1000, 300000),
      openEventStream: _openEventStream,
      deleteSessionOnClose: _deleteSessionOnClose,
    );

    if (!validate) {
      return server;
    }

    if (server.name.isEmpty) {
      throw const AppException.validation('Server name is required');
    }
    if (server.isStdio && server.command.isEmpty) {
      throw const AppException.validation('Command is required for stdio MCP');
    }
    if (server.isStreamableHttp && server.url.isEmpty) {
      throw const AppException.validation('URL is required for HTTP MCP');
    }

    return server;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 720),
      title: Text(
        widget.initial == null ? 'Add MCP server' : 'Edit MCP server',
      ),
      content: SingleChildScrollView(
        padding: const .only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Server ID: ${_baseServer.id.isEmpty ? '(generated on save)' : _baseServer.id}',
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Name',
              child: TextBox(controller: _nameController),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Transport',
              child: Align(
                alignment: .centerLeft,
                child: ComboBox<McpTransportType>(
                  value: _transportType,
                  items: const [
                    ComboBoxItem(
                      value: McpTransportType.stdio,
                      child: Text('stdio'),
                    ),
                    ComboBoxItem(
                      value: McpTransportType.streamableHttp,
                      child: Text('streamable-http'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _transportType = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ToggleSwitch(
              checked: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
              content: Text(_enabled ? 'Enabled' : 'Disabled'),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Request timeout (ms)',
              hint: 'Used for both stdio and streamable HTTP transports.',
              child: NumberBox(
                value: int.tryParse(_timeoutController.text) ?? 30000,
                min: 1000,
                max: 300000,
                mode: SpinButtonPlacementMode.compact,
                smallChange: 1000,
                onChanged: (value) {
                  _timeoutController.text = (value?.round() ?? 30000)
                      .clamp(1000, 300000)
                      .toString();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_transportType == McpTransportType.stdio) ...[
              _Field(
                label: 'Command',
                child: TextBox(controller: _commandController),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Arguments',
                hint: 'One argument per line.',
                child: TextBox(
                  controller: _argsController,
                  minLines: 3,
                  maxLines: 6,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Working directory',
                child: TextBox(controller: _workingDirectoryController),
              ),
              const SizedBox(height: 12),
              ToggleSwitch(
                checked: _includeParentEnvironment,
                onChanged: (value) {
                  setState(() {
                    _includeParentEnvironment = value;
                  });
                },
                content: const Text('Include parent environment'),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Environment',
                hint: 'Use KEY=VALUE format, one entry per line.',
                child: TextBox(
                  controller: _environmentController,
                  minLines: 4,
                  maxLines: 8,
                ),
              ),
            ] else ...[
              _Field(
                label: 'URL',
                child: TextBox(controller: _urlController),
              ),
              const SizedBox(height: 12),
              ToggleSwitch(
                checked: _openEventStream,
                onChanged: (value) {
                  setState(() {
                    _openEventStream = value;
                  });
                },
                content: const Text('Open event stream'),
              ),
              const SizedBox(height: 12),
              ToggleSwitch(
                checked: _deleteSessionOnClose,
                onChanged: (value) {
                  setState(() {
                    _deleteSessionOnClose = value;
                  });
                },
                content: const Text('Delete session on close'),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Headers',
                hint: 'Use KEY=VALUE format, one entry per line.',
                child: TextBox(
                  controller: _headersController,
                  minLines: 4,
                  maxLines: 8,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Button(
          onPressed: _testing ? null : _onTest,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_testing)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: ProgressRing(strokeWidth: 2),
                ),
              if (_testing) const SizedBox(width: 8),
              const Text('Test'),
            ],
          ),
        ),
        FilledButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _Field({required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.typography.bodyStrong),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: theme.typography.caption),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

String _formatMap(Map<String, String> map) {
  return map.entries.map((entry) => '${entry.key}=${entry.value}').join('\n');
}

List<String> _parseLines(String text) {
  return text
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _parseMap(String text) {
  final result = <String, String>{};
  for (final rawLine in text.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final index = line.indexOf('=');
    if (index <= 0) {
      throw AppException.validation('Invalid KEY=VALUE entry: $line');
    }
    final key = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    if (key.isEmpty) {
      throw AppException.validation('Invalid KEY=VALUE entry: $line');
    }
    result[key] = value;
  }
  return result;
}
