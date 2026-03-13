part of '_message_list.dart';

class _AnimatedEmptyPlaceholder extends StatelessWidget {
  static const Duration _showDuration = Duration(milliseconds: 1500);
  static const Duration _hideDuration = Duration(milliseconds: 600);

  final bool show;

  const _AnimatedEmptyPlaceholder({required this.show});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: _showDuration,
        reverseDuration: _hideDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: show
            ? const _EmptyPlaceholder(key: ValueKey<String>('empty-chat'))
            : const SizedBox.shrink(key: ValueKey<String>('empty-chat-hidden')),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          const Text('🐦‍⬛', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('没有内容...', style: context.fluent.typography.body),
        ],
      ),
    );
  }
}
