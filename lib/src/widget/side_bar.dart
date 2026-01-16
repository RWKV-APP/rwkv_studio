import 'package:fluent_ui/fluent_ui.dart';

class CollapsibleSidebarLayout extends StatefulWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;
  final bool open;
  final Widget? divider;

  const CollapsibleSidebarLayout({
    super.key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 240,
    this.divider,
    this.open = true,
  });

  @override
  State<CollapsibleSidebarLayout> createState() =>
      _CollapsibleSidebarLayoutState();
}

class _CollapsibleSidebarLayoutState extends State<CollapsibleSidebarLayout> {
  late bool _open;

  late final isNarrow = MediaQuery.of(context).size.width < 900;

  @override
  void initState() {
    super.initState();
    _open = widget.open;
  }

  @override
  void didUpdateWidget(covariant CollapsibleSidebarLayout old) {
    if (old.open != widget.open) {
      _open = widget.open;
    }
    super.didUpdateWidget(old);
  }

  @override
  Widget build(BuildContext context) {
    final showOverlay = isNarrow;
    final width = widget.sidebarWidth;

    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(child: widget.content),
            if (widget.divider != null) widget.divider!,
            if (!showOverlay)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: _open ? width : 0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: widget.sidebarWidth,
                    minWidth: widget.sidebarWidth,
                    child: widget.sidebar,
                  ),
                ),
              ),
          ],
        ),

        if (showOverlay)
          _OverlaySidebar(
            isOpen: _open,
            width: width,
            onClose: () {
              setState(() {
                _open = false;
              });
            },
            sidebar: widget.sidebar,
          ),
      ],
    );
  }
}

class _OverlaySidebar extends StatelessWidget {
  final bool isOpen;
  final double width;
  final VoidCallback onClose;
  final Widget sidebar;

  const _OverlaySidebar({
    required this.isOpen,
    required this.width,
    required this.onClose,
    required this.sidebar,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isOpen,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: onClose,
              child: ColoredBox(color: Colors.black.withAlpha(120)),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: 0,
            bottom: 0,
            left: isOpen ? 0 : -width,
            width: width,
            child: sidebar,
          ),
        ],
      ),
    );
  }
}
