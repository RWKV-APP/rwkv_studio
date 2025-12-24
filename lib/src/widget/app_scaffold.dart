import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? titleBar;
  final AppNavigationBar? navigationBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.navigationBar,
    this.titleBar,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    final theme = Theme.of(context);

    if (navigationBar != null) {
      content = Row(
        children: [
          Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: navigationBar!,
          ),
          VerticalDivider(width: .5, thickness: .5),
          Expanded(child: body),
        ],
      );
    }
    if (titleBar != null) {
      content = Column(
        children: [
          titleBar!,
          Expanded(child: content),
        ],
      );
    }
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 0,
      child: content,
    );
  }
}

class NavigationEntry {
  final Widget icon;
  final String label;

  NavigationEntry({required this.icon, required this.label});
}

class AppNavigationBar extends StatefulWidget {
  final List<NavigationEntry> navigationBarItems;
  final int? navigationBarSelectedIndex;
  final void Function(int)? onNavigationBarItemSelected;

  const AppNavigationBar({
    super.key,
    required this.navigationBarItems,
    required this.navigationBarSelectedIndex,
    required this.onNavigationBarItemSelected,
  });

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  late int _selectedIndex = widget.navigationBarSelectedIndex ?? 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onNavigationBarItemSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, entry) in widget.navigationBarItems.indexed)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: _NavigationBarItem(
              icon: entry.icon,
              label: entry.label,
              selected: _selectedIndex == index,
              onPressed: () => _onItemSelected(index),
            ),
          ),
      ],
    );
  }
}

class _NavigationBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _NavigationBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return IconButton.filled(
        icon: IconTheme(
          data: IconTheme.of(context).copyWith(color: Colors.white),
          child: icon,
        ),
        onPressed: onPressed,
        tooltip: label,
        iconSize: 20,
      );
    }
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: label,
      iconSize: 20,
    );
  }
}
