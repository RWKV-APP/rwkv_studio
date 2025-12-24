import 'package:flutter/material.dart';

/// Visual playground that renders most themed widgets together.
class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController(
    text: 'search embeddings...',
  );
  final TextEditingController _multilineController = TextEditingController(
    text: 'System prompt goes here. Markdown + code fences supported.',
  );

  bool _switchValue = true;
  bool _checkboxValue = false;
  int _radioValue = 0;
  double _sliderValue = 40;
  int _navigationIndex = 0;
  String _dropdownValue = 'fast';
  final Set<String> _filterSelection = {'Voice'};
  String _choiceChip = 'Chat';
  int _segmentedValue = 0;

  static const List<String> _chipLabels = ['Chat', 'Voice', 'TTS', 'Agent'];
  static const List<String> _dropdownOptions = ['fast', 'balanced', 'accurate'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _multilineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Preview'),
        actions: [
          IconButton(
            tooltip: 'Show dialog',
            icon: const Icon(Icons.layers),
            onPressed: () => _showDialog(context),
          ),
          IconButton(
            tooltip: 'Show snackbar',
            icon: const Icon(Icons.message_outlined),
            onPressed: () => _showSnack(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.bolt),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(360.0, 1200.0);
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBanner(scheme: scheme),
                    const SizedBox(height: 24),
                    ThemePreviewSection(
                      title: 'Buttons & Iconography',
                      subtitle: 'Primary actions rendered across button types',
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Elevated'),
                          ),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('Filled'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Outlined'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Text'),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.settings),
                          ),
                          IconButton.filled(
                            onPressed: () {},
                            icon: const Icon(Icons.code),
                          ),
                          IconButton.outlined(
                            onPressed: () {},
                            icon: const Icon(Icons.share),
                          ),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Live')),
                              ButtonSegment(value: 1, label: Text('Preview')),
                              ButtonSegment(value: 2, label: Text('History')),
                            ],
                            selected: {_segmentedValue},
                            onSelectionChanged: (values) =>
                                setState(() => _segmentedValue = values.first),
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Inputs & Toggles',
                      subtitle:
                          'Text fields, switches, sliders, radios, and dropdowns',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: 280,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Search',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 320,
                                child: TextField(
                                  controller: _multilineController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'System Prompt',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  value: _dropdownValue,
                                  decoration: const InputDecoration(
                                    labelText: 'Profile',
                                  ),
                                  items: _dropdownOptions
                                      .map(
                                        (option) => DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() {
                                    if (value != null) {
                                      _dropdownValue = value;
                                    }
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: _switchValue,
                                    onChanged: (value) =>
                                        setState(() => _switchValue = value),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Audio streaming'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _checkboxValue,
                                    onChanged: (value) => setState(
                                      () => _checkboxValue = value ?? false,
                                    ),
                                  ),
                                  const Text('Vector store'),
                                ],
                              ),
                              Wrap(
                                spacing: 16,
                                children: List.generate(3, (index) {
                                  return Radio<int>(
                                    value: index,
                                    groupValue: _radioValue,
                                    onChanged: (value) => setState(
                                      () => _radioValue = value ?? 0,
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(
                                width: 240,
                                child: Slider(
                                  value: _sliderValue,
                                  min: 0,
                                  max: 100,
                                  divisions: 5,
                                  label: '${_sliderValue.round()}%',
                                  onChanged: (value) =>
                                      setState(() => _sliderValue = value),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Chips & Badges',
                      subtitle: 'Filter, choice, and assist chips',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          for (final label in _chipLabels)
                            FilterChip(
                              label: Text(label),
                              selected: _filterSelection.contains(label),
                              onSelected: (value) => setState(() {
                                if (value) {
                                  _filterSelection.add(label);
                                } else {
                                  _filterSelection.remove(label);
                                }
                              }),
                            ),
                          for (final label in _chipLabels.take(3))
                            ChoiceChip(
                              label: Text(label),
                              selected: _choiceChip == label,
                              onSelected: (_) =>
                                  setState(() => _choiceChip = label),
                            ),
                          InputChip(
                            avatar: const CircleAvatar(
                              child: Icon(Icons.memory, size: 16),
                            ),
                            label: const Text('LLM Kernel'),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Navigation & Tabs',
                      subtitle:
                          'NavigationRail, TabBar, and Breadcrumb samples',
                      child: Column(
                        children: [
                          SizedBox(
                            height: 240,
                            child: Row(
                              children: [
                                NavigationRail(
                                  selectedIndex: _navigationIndex,
                                  onDestinationSelected: (index) =>
                                      setState(() => _navigationIndex = index),
                                  destinations: const [
                                    NavigationRailDestination(
                                      icon: Icon(Icons.chat_bubble_outline),
                                      selectedIcon: Icon(Icons.chat),
                                      label: Text('Chat'),
                                    ),
                                    NavigationRailDestination(
                                      icon: Icon(Icons.graphic_eq_outlined),
                                      selectedIcon: Icon(Icons.graphic_eq),
                                      label: Text('Audio'),
                                    ),
                                    NavigationRailDestination(
                                      icon: Icon(Icons.settings_outlined),
                                      selectedIcon: Icon(Icons.settings),
                                      label: Text('Settings'),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        children: const [
                                          Chip(label: Text('Home')),
                                          Icon(Icons.chevron_right),
                                          Chip(label: Text('Playground')),
                                          Icon(Icons.chevron_right),
                                          Chip(label: Text('Chat Flow')),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TabBar(
                                        controller: _tabController,
                                        tabs: const [
                                          Tab(text: 'Stream'),
                                          Tab(text: 'Deterministic'),
                                          Tab(text: 'Benchmark'),
                                        ],
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: const [
                                            _TabContent('Streaming tokens…'),
                                            _TabContent('Deterministic run'),
                                            _TabContent('Benchmark stats'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Cards, Lists & Data',
                      subtitle: 'Card, ListTile, ExpansionTile, and DataTable',
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: 320,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'RWKV Studio',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Desktop tuned Flutter runtime with geek aesthetic.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('Launch demo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 320,
                                child: Card(
                                  child: Column(
                                    children: const [
                                      ListTile(
                                        leading: Icon(Icons.chat),
                                        title: Text('Chat Session'),
                                        subtitle: Text(
                                          '12 prompts • 2 attachments',
                                        ),
                                        trailing: Icon(Icons.chevron_right),
                                      ),
                                      Divider(height: 1),
                                      ListTile(
                                        leading: Icon(Icons.graphic_eq),
                                        title: Text('Audio Lab'),
                                        subtitle: Text(
                                          'Real-time synthesis enabled',
                                        ),
                                        trailing: Icon(Icons.chevron_right),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text('Advanced options'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Use this section to ensure ExpansionTile styles stay in sync with the theme.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Model')),
                              DataColumn(label: Text('Params')),
                              DataColumn(label: Text('Latency')),
                            ],
                            rows: const [
                              DataRow(
                                cells: [
                                  DataCell(Text('RWKV-x070B')),
                                  DataCell(Text('7B')),
                                  DataCell(Text('125ms')),
                                ],
                              ),
                              DataRow(
                                cells: [
                                  DataCell(Text('RWKV-x014B')),
                                  DataCell(Text('14B')),
                                  DataCell(Text('220ms')),
                                ],
                              ),
                              DataRow(
                                cells: [
                                  DataCell(Text('RWKV-x030B')),
                                  DataCell(Text('30B')),
                                  DataCell(Text('410ms')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Progress & Feedback',
                      subtitle:
                          'Linear/Circular indicators plus banners and tooltips',
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: _sliderValue / 100,
                            ),
                          ),
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(),
                          ),
                          Tooltip(
                            message: 'Hover to validate tooltip colors',
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundColor: scheme.primary,
                                child: const Icon(
                                  Icons.info,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              label: const Text('Hover me'),
                            ),
                          ),
                          MaterialBanner(
                            content: const Text('Network is stable.'),
                            leading: const Icon(Icons.cloud_done),
                            backgroundColor: scheme.surfaceVariant,
                            actions: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('DISMISS'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ThemePreviewSection(
                      title: 'Color Swatches',
                      subtitle: 'Primary palette pulled from ColorScheme',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ColorSwatchTile(
                            label: 'primary',
                            color: scheme.primary,
                          ),
                          _ColorSwatchTile(
                            label: 'secondary',
                            color: scheme.secondary,
                          ),
                          _ColorSwatchTile(
                            label: 'surface',
                            color: scheme.surface,
                            borderColor: scheme.outline,
                          ),
                          _ColorSwatchTile(
                            label: 'surfaceVariant',
                            color: scheme.surfaceVariant,
                            borderColor: scheme.outlineVariant,
                          ),
                          _ColorSwatchTile(label: 'error', color: scheme.error),
                          _ColorSwatchTile(
                            label: 'outline',
                            color: scheme.outline,
                          ),
                          _ColorSwatchTile(
                            label: 'shadow',
                            color: scheme.shadow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Themed snackbar preview'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm change'),
          content: const Text(
            'This dialog confirms that alert theming stays consistent.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('APPLY'),
            ),
          ],
        );
      },
    );
  }
}

class ThemePreviewSection extends StatelessWidget {
  const ThemePreviewSection({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withOpacity(0.75),
            scheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RWKV Studio Theme Lab',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inspect every component rendered with the LightTheme to ensure color, '
            'typography, and density align with the desktop design language.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({
    required this.label,
    required this.color,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      width: 120,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : Border.all(color: color.withOpacity(0.35)),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
