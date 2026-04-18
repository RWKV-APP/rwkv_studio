part of 'app_cubit.dart';

enum ComponentType {
  rwkvLightning(name: 'rwkv_lightning'),
  rwkvLightningPython(name: 'rwkv_lightning_python');

  final String name;

  const ComponentType({required this.name});
}

class AppComponent {
  final ComponentType type;
  final bool enabled;
  final bool missing;
  final bool external;
  final String dir;
  final String path;
  final AppComponentInfo info;
  final AppComponentInfo latest;

  bool get hasUpdate =>
      missing ||
      latest != AppComponentInfo.empty && latest.versionCode > info.versionCode;

  static const List<AppComponent> defaultComponents = [
    AppComponent(
      dir: '',
      type: ComponentType.rwkvLightning,
      enabled: true,
      missing: true,
      external: false,
      path: 'rwkv_lightning.exe',
      info: AppComponentInfo.empty,
      latest: AppComponentInfo.empty,
    ),
  ];

  const AppComponent({
    required this.dir,
    required this.type,
    required this.enabled,
    required this.missing,
    required this.external,
    required this.path,
    required this.info,
    required this.latest,
  });

  AppComponent copyWith({
    ComponentType? type,
    bool? enabled,
    bool? missing,
    String? path,
    bool? external,
    String? dir,
    AppComponentInfo? info,
    AppComponentInfo? latest,
  }) {
    return AppComponent(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      missing: missing ?? this.missing,
      path: path ?? this.path,
      external: external ?? this.external,
      dir: dir ?? this.dir,
      info: info ?? this.info,
      latest: latest ?? this.latest,
    );
  }
}
