part of 'flow_page.dart';

class _Toolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Card(
          padding: const .symmetric(horizontal: 6, vertical: 4),
          child: IconButton(
            icon: const Icon(FluentIcons.collapse_menu),
            onPressed: () {
              // context.nodeFlow.add(const NodeFlowToggleDebug());
            },
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text("ReAct Agent Demo", maxLines: 1, overflow: .ellipsis),
        ),
        _DebugActionGroup(),
        const SizedBox(width: 12),
        Card(
          padding: const .symmetric(horizontal: 6, vertical: 4),
          child: IconButton(
            icon: const Icon(FluentIcons.chat_bot),
            onPressed: () {
              context.nodeFlow.add(const NodeFlowToggleDebug());
            },
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _DebugActionGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const .symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: .min,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.focus_view),
            onPressed: () {
              context.nodeFlow.controller.centerViewport();
            },
          ),
          IconButton(
            icon: const Icon(FluentIcons.folder_open),
            onPressed: () async {
              final file = await FileUtils.openFileString(
                extension: ".json",
              ).withToast(context);
              if (file != null && context.mounted) {
                context.nodeFlow.add(NodeFlowGraphImportFile(jsonDecode(file)));
              }
            },
          ),
          IconButton(
            icon: const Icon(FluentIcons.download_document),
            onPressed: () {
              final graph = context.nodeFlow.exportGraph();
              final json = graph.toJsonString();
              FileUtils.saveFileString(content: json, extension: ".json");
            },
          ),
          IconButton(
            icon: Icon(FluentIcons.play, color: Colors.green.lightest),
            onPressed: () {
              //
            },
          ),
        ],
      ),
    );
  }
}
