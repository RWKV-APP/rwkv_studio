part of 'setting_page.dart';

class CacheSettingsCard extends StatelessWidget {
  final CacheSettingState cache;

  const CacheSettingsCard({super.key, required this.cache});

  void _onTapChangeModelDir(BuildContext context) async {
    final current = File(cache.modelDownloadDir).absolute.path;
    final dir = await getDirectoryPath(initialDirectory: current);
    if (dir == null || !context.mounted || dir == current) {
      return;
    }
    // final migration = await _askMigrationModels(context, current, dir);
    // if (!context.mounted || migration == null) {
    //   return;
    // }
    await context.modelManage.setModelDownloadDir(dir, migration: false);
    if (!context.mounted) {
      return;
    }
    context.settings.setCacheSetting(cache.copyWith(modelDownloadDir: dir));
  }

  void _onTapChangeAppCacheDir(BuildContext context) async {
    final current = File(cache.appCacheDir).absolute.path;
    final dir = await getDirectoryPath(initialDirectory: current);
    if (dir == null || !context.mounted) {
      return;
    }
    context.settings.setCacheSetting(cache.copyWith(appCacheDir: dir));
  }

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: const Text('缓存设置'),
      content: Column(
        crossAxisAlignment: .stretch,
        children: [
          Column(
            crossAxisAlignment: .stretch,
            children: [
              const Text('模型下载目录'),
              const SizedBox(width: 12, height: 12),
              SizedBox(
                width: 300,
                child: TextBox(
                  controller: TextEditingController(
                    text: cache.modelDownloadDir,
                  ),
                  readOnly: true,
                  suffix: IconButton(
                    icon: const Icon(WindowsIcons.folder),
                    onPressed: () => _onTapChangeModelDir(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ModelCacheInfo(dir: cache.modelDownloadDir),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: .stretch,
            children: [
              const Text('缓存目录'),
              const SizedBox(width: 12, height: 12),
              SizedBox(
                width: 300,
                child: TextBox(
                  controller: TextEditingController(text: cache.appCacheDir),
                  readOnly: true,
                  suffix: IconButton(
                    icon: const Icon(WindowsIcons.folder),
                    onPressed: () => _onTapChangeAppCacheDir(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCacheInfo extends StatefulWidget {
  final String dir;

  const _ModelCacheInfo({required this.dir});

  @override
  State<_ModelCacheInfo> createState() => _ModelCacheInfoState();
}

class _ModelCacheInfoState extends State<_ModelCacheInfo> {
  DirFileInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _loading = true;
      });
      final dir = widget.dir;
      _info = await FileUtils.getDirectoryFileInfo(dir, excludeExts: {'json'});
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _ModelCacheInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final mb = (_info?.size ?? 0) / 1024 / 1024;
    return Text(
      _loading
          ? '计算中...'
          : '${_info?.count} 个模型文件,  共计占用 ${mb.toStringAsFixed(2)} MB',
      style: context.fluent.typography.caption,
    );
  }
}

Future<bool?> _askMigrationModels(
  BuildContext context,
  String old,
  String dir,
) async {
  final r = await showDialog<bool?>(
    context: context,
    builder: (ctx) => ContentDialog(
      title: const Text('迁移模型'),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(
            '是否需要迁移模型文件到新目录？\n\n'
            '旧目录 $old\n'
            '新目录 $dir',
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: () async {
              return await Directory(dir).list().toList();
            }(),
            builder: (ctx, snapshot) {
              final count = snapshot.data?.length ?? 0;
              final ignore =
                  (snapshot.data
                          ?.where(
                            (e) => e.path.contains('.rwkv_downloader.json'),
                          )
                          .length ??
                      0) >
                  0;
              if (count <= 0 || ignore) {
                return const SizedBox();
              }
              return const InfoBar(
                title: Text('请注意, 目标文件夹不是空文件夹'),
                severity: InfoBarSeverity.warning,
              );
            },
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('不迁移'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FilledButton(
          child: const Text('迁移'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return r ?? false;
}
