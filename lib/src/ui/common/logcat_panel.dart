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

  Offset _downOffset = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    AppLog.instance.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    AppLog.instance.removeListener(_onLogChanged);
    super.dispose();
  }

  void _onLogChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppLog.instance.history;
    return Stack(
      children: [
        Positioned(
          left: _offset?.dx,
          top: _offset?.dy,
          right: _offset == null ? 0 : null,
          bottom: _offset == null ? 0 : null,
          width: 800,
          height: 400,
          child: DragEditable(
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
            child: Card(
              padding: .zero,
              backgroundColor: Colors.grey[140],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.grey[180],
                    child: Row(
                      children: [
                        const Text(
                          'Logcat',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                          ),
                          icon: const Icon(
                            FluentIcons.delete,
                            size: 14,
                            color: Colors.white,
                          ),
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
                          icon: const Icon(
                            FluentIcons.cancel,
                            size: 14,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            LogcatPanel.attachToRootOverlay(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1000,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: logs.length,
                          padding: const EdgeInsets.all(8),
                          reverse: true,
                          itemBuilder: (ctx, index) {
                            return SelectableText(
                              logs[logs.length - index - 1].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
