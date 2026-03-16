import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/repository/mcp_repository.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class McpPage extends StatelessWidget {
  const McpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<McpRepository>();

    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: BlocBuilder<SettingCubit, SettingState>(
              buildWhen: (previous, current) => previous.mcp != current.mcp,
              builder: (context, state) {
                return StreamBuilder<McpRepositorySnapshot>(
                  stream: repository.watchSnapshot(),
                  initialData: repository.snapshot,
                  builder: (context, snapshot) {
                    final runtime = snapshot.data ?? repository.snapshot;
                    return _McpBody(settings: state.mcp, runtime: runtime);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _McpBody extends StatelessWidget {
  final McpSettingsModel settings;
  final McpRepositorySnapshot runtime;

  const _McpBody({required this.settings, required this.runtime});

  int get _enabledCount =>
      settings.servers.where((item) => item.enabled).length;

  int get _connectedCount =>
      runtime.statuses.values.where((item) => item.connected).length;

  Future<void> _refresh(BuildContext context) async {
    try {
      await context.read<McpRepository>().refreshConnections();
    } catch (_) {}
  }

  void _updateSettings(BuildContext context, McpSettingsModel next) {
    context.settings.setMcpSetting(next);
  }

  Future<void> _showEditor(
    BuildContext context, {
    McpServerModel? server,
  }) async {
    final result = await _McpServerDialog.show(context, initial: server);
    if (result == null || !context.mounted) {
      return;
    }

    final servers = [...settings.servers];
    final index = servers.indexWhere((item) => item.id == result.id);
    if (index >= 0) {
      servers[index] = result;
    } else {
      servers.insert(0, result);
    }

    _updateSettings(context, settings.copyWith(servers: servers));
  }

  Future<void> _removeServer(
    BuildContext context,
    McpServerModel server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Remove MCP server'),
          content: Text('Remove "${server.name}" from MCP settings?'),
          actions: [
            Button(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    _updateSettings(
      context,
      settings.copyWith(
        servers: settings.servers
            .where((item) => item.id != server.id)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _testServer(BuildContext context, McpServerModel server) async {
    await context
        .read<McpRepository>()
        .testConnection(server)
        .withToast(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MCP', style: theme.typography.subtitle),
        const SizedBox(height: 16),
        Expander(
          header: const Text('Runtime'),
          contentBackgroundColor: context.fluent.cardColor,
          content: Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: _SettingBlock(
                  label: 'Namespace tool names',
                  hint: 'Prefix tools with the MCP server name.',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ToggleSwitch(
                      checked: settings.namespaceToolNames,
                      onChanged: (value) {
                        _updateSettings(
                          context,
                          settings.copyWith(namespaceToolNames: value),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 280,
                child: _SettingBlock(
                  label: 'Max tool rounds',
                  hint: 'Maximum number of MCP tool call rounds per request.',
                  child: NumberBox(
                    value: settings.maxToolRounds,
                    min: 1,
                    max: 32,
                    mode: SpinButtonPlacementMode.compact,
                    smallChange: 1,
                    onChanged: (value) {
                      final rounds = value?.round() ?? settings.maxToolRounds;
                      _updateSettings(
                        context,
                        settings.copyWith(maxToolRounds: rounds.clamp(1, 32)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expander(
          header: const Text('Servers'),
          trailing: Text(
            '$_connectedCount connected / $_enabledCount enabled / ${settings.servers.length} total',
            style: theme.typography.caption,
          ),
          initiallyExpanded: true,
          contentBackgroundColor: context.fluent.cardColor,
          contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  FilledButton(
                    onPressed: () => _showEditor(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.add),
                        SizedBox(width: 8),
                        Text('Add server'),
                      ],
                    ),
                  ),
                  Button(
                    onPressed: () => _refresh(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (settings.servers.isEmpty)
                Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.fluent.cardColor.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.fluent.inactiveBackgroundColor,
                    ),
                  ),
                  child: Text(
                    'No MCP server configured.',
                    style: theme.typography.body,
                  ),
                ),
              for (final server in settings.servers) ...[
                _McpServerCard(
                  server: server,
                  status: runtime.statuses[server.id],
                  onChanged: (value) {
                    final servers = settings.servers
                        .map((item) => item.id == value.id ? value : item)
                        .toList(growable: false);
                    _updateSettings(
                      context,
                      settings.copyWith(servers: servers),
                    );
                  },
                  onEdit: () => _showEditor(context, server: server),
                  onDelete: () => _removeServer(context, server),
                  onTest: () => _testServer(context, server),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _McpServerCard extends StatelessWidget {
  final McpServerModel server;
  final McpServerStatus? status;
  final ValueChanged<McpServerModel> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _McpServerCard({
    required this.server,
    required this.status,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final currentStatus = status ?? const McpServerStatus.disabled();

    String name = server.id;
    if (currentStatus.serverName.isNotEmpty) {
      name = currentStatus.serverVersion.isEmpty
          ? currentStatus.serverName
          : '${currentStatus.serverName} ${currentStatus.serverVersion}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fluent.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.fluent.inactiveBackgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(name, style: context.fluent.typography.bodyStrong),
              ),
              ToggleSwitch(
                checked: server.enabled,
                onChanged: (value) =>
                    onChanged(server.copyWith(enabled: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            server.isStdio
                ? _stdioSummary(server)
                : 'URL: ${server.url.isEmpty ? '-' : server.url}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(status: currentStatus),

              _Tag(
                label: server.isStdio ? 'stdio' : 'streamable-http',
                icon: server.isStdio
                    ? FluentIcons.command_prompt
                    : FluentIcons.link,
              ),
              if (currentStatus.connected)
                _Tag(
                  label: '${currentStatus.toolCount} tools',
                  icon: FluentIcons.toolbox,
                ),
            ],
          ),
          if (server.isStdio && server.environment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Environment: ${server.environment.keys.join(', ')}',
              style: theme.typography.caption,
            ),
          ],
          if (server.isStreamableHttp && server.headers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Headers: ${server.headers.keys.join(', ')}',
              style: theme.typography.caption,
            ),
          ],
          if (currentStatus.error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              currentStatus.error,
              style: theme.typography.caption?.copyWith(
                color: Colors.errorPrimaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: .end,
            children: [
              Button(
                onPressed: onTest,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.plug_connected),
                    SizedBox(width: 8),
                    Text('Test'),
                  ],
                ),
              ),
              Button(
                onPressed: onEdit,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              Button(
                onPressed: onDelete,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.delete),
                    SizedBox(width: 8),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final McpServerStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.enabled) {
      return const _Tag(label: 'disabled', icon: FluentIcons.blocked2);
    }
    if (status.checking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.fluent.inactiveBackgroundColor.withAlpha(100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: ProgressRing(strokeWidth: 2),
            ),
            SizedBox(width: 6),
            Text('checking', style: TextStyle(fontSize: 12, height: 1)),
          ],
        ),
      );
    }
    if (status.connected) {
      return _Tag(
        label: 'connected',
        icon: FluentIcons.check_mark,
        foregroundColor: Colors.green,
      );
    }
    return const _Tag(
      label: 'error',
      icon: FluentIcons.warning,
      foregroundColor: Colors.errorPrimaryColor,
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? foregroundColor;

  const _Tag({required this.label, required this.icon, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? context.fluent.inactiveColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.fluent.inactiveBackgroundColor.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, height: 1)),
        ],
      ),
    );
  }
}

class _SettingBlock extends StatelessWidget {
  final String label;
  final String hint;
  final Widget child;

  const _SettingBlock({
    required this.label,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.typography.bodyStrong),
        const SizedBox(height: 4),
        Text(hint, style: theme.typography.caption),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

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

String _stdioSummary(McpServerModel server) {
  final args = server.args.isEmpty ? '' : ' ${server.args.join(' ')}';
  final cwd = server.workingDirectory.isEmpty
      ? ''
      : '  |  cwd: ${server.workingDirectory}';
  return 'Command: ${server.command}$args$cwd';
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

String _formatTime(DateTime value) {
  String twoDigits(int input) => input.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
}
