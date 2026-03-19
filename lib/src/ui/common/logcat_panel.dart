import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

class LogcatPanel extends StatefulWidget {
  static OverlayEntry? _entry;

  const LogcatPanel({super.key});

  static void attachToRootOverlay(BuildContext context) {
    final rootOverlay = Overlay.of(context, rootOverlay: true);

    if (_entry != null) {
      _entry?.remove();
      _entry = null;
      return;
    }
    _entry = OverlayEntry(
      builder: (ctx) {
        return const Positioned.fill(child: LogcatPanel());
      },
    );
    rootOverlay.insert(_entry!);
  }

  @override
  State<LogcatPanel> createState() => _LogcatPanelState();
}

class _LogcatPanelState extends State<LogcatPanel> {
  static Offset? _offset;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  Offset _downOffset = const Offset(0, 0);
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    AppLog.instance.addListener(_onLogChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    AppLog.instance.removeListener(_onLogChanged);
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _onLogChanged() {
    final bool shouldFollowLatest =
        !_verticalController.hasClients ||
        (_verticalController.position.maxScrollExtent -
                _verticalController.offset) <
            40;
    setState(() {});
    if (shouldFollowLatest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_verticalController.hasClients) {
      return;
    }
    _verticalController.jumpTo(_verticalController.position.maxScrollExtent);
  }

  String _buildLogText(List<Log> logs) {
    if (logs.isEmpty) {
      return '';
    }
    return logs.map((e) => e.toString()).join('\n');
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget panelCard = Card(
      padding: .zero,
      backgroundColor: Colors.grey[140],
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: _isFullScreen ? 0 : _offset?.dx,
          top: _isFullScreen ? 0 : _offset?.dy,
          right: _isFullScreen ? 0 : (_offset == null ? 0 : null),
          bottom: _isFullScreen ? 0 : (_offset == null ? 0 : null),
          width: _isFullScreen ? null : 800,
          height: _isFullScreen ? null : 400,
          child: _isFullScreen
              ? panelCard
              : DragEditable(
                  dragArea: const Rect.fromLTWH(0, 0, 800, 24),
                  onStartUpdatePosition: (details) {
                    _downOffset = details.localPosition;
                  },
                  onUpdate: (detail) {
                    final pos = detail.globalPosition - _downOffset;
                    setState(() {
                      _offset = pos;
                    });
                  },
                  handleRadius: 0,
                  child: panelCard,
                ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final logs = AppLog.instance.history;
    final screenWidth = MediaQuery.of(context).size.width - 30;
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        notificationPredicate: (notification) {
          return notification.metrics.axis == Axis.horizontal;
        },
        child: SingleChildScrollView(
          controller: _verticalController,
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: screenWidth),
              child: SelectableText(
                _buildLogText(logs),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: Colors.white,
                ),
                maxLines: null,
                minLines: 1,
                textWidthBasis: TextWidthBasis.longestLine,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[180],
      child: Row(
        children: [
          const Text('日志', style: TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            icon: Icon(
              _isFullScreen
                  ? FluentIcons.chrome_restore
                  : FluentIcons.full_screen,
              size: 14,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
          ),
          const SizedBox(width: 4),
          IconButton(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            icon: const Icon(FluentIcons.delete, size: 14, color: Colors.white),
            onPressed: () {
              AppLog.instance.history.clear();
              setState(() {});
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            icon: const Icon(FluentIcons.cancel, size: 14, color: Colors.white),
            onPressed: () {
              LogcatPanel.attachToRootOverlay(context);
            },
          ),
        ],
      ),
    );
  }
}
