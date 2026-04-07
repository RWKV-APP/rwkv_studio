import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/repository/mcp_repository.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

part '_add_mcp_server_dialog.dart';

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
        Text('MCP Server', style: theme.typography.subtitle),
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

    String name = server.name;
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
          const SizedBox(height: 8),

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

          Row(
            children: [
              Expanded(child: tags(currentStatus)),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: .end,
                children: [
                  Button(
                    onPressed: onTest,
                    child: const Icon(FluentIcons.plug_connected),
                  ),
                  Button(
                    onPressed: onEdit,
                    child: const Icon(FluentIcons.edit),
                  ),
                  Button(
                    onPressed: onDelete,
                    child: const Icon(FluentIcons.delete),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tags(McpServerStatus currentStatus) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusBadge(status: currentStatus),

        _Tag(
          label: server.isStdio ? 'stdio' : 'streamable-http',
          icon: server.isStdio ? FluentIcons.command_prompt : FluentIcons.link,
        ),
        if (currentStatus.connected)
          _Tag(
            label: '${currentStatus.toolCount} tools',
            icon: FluentIcons.toolbox,
          ),
      ],
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
