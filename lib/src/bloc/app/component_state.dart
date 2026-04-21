part of 'app_cubit.dart';

enum ComponentType {
  toolkit(name: 'toolkit'),
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
  final String bin;
  final AppComponentInfo info;
  final AppComponentInfo latest;

  bool get hasUpdate =>
      missing ||
      latest != AppComponentInfo.empty && latest.versionCode > info.versionCode;

  static const Map<ComponentType, AppComponent> defaultComponents = {
    ComponentType.toolkit: AppComponent(
      dir: '',
      type: ComponentType.toolkit,
      enabled: true,
      missing: true,
      external: false,
      bin: 'toolkit.exe',
      info: AppComponentInfo.empty,
      latest: AppComponentInfo.empty,
    ),
    ComponentType.rwkvLightning: AppComponent(
      dir: '',
      type: ComponentType.rwkvLightning,
      enabled: true,
      missing: true,
      external: false,
      bin: 'rwkv_lightning.exe',
      info: AppComponentInfo.empty,
      latest: AppComponentInfo.empty,
    ),
  };

  const AppComponent({
    required this.dir,
    required this.type,
    required this.enabled,
    required this.missing,
    required this.external,
    required this.bin,
    required this.info,
    required this.latest,
  });

  AppComponent copyWith({
    ComponentType? type,
    bool? enabled,
    bool? missing,
    String? bin,
    bool? external,
    String? dir,
    AppComponentInfo? info,
    AppComponentInfo? latest,
  }) {
    return AppComponent(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      missing: missing ?? this.missing,
      bin: bin ?? this.bin,
      external: external ?? this.external,
      dir: dir ?? this.dir,
      info: info ?? this.info,
      latest: latest ?? this.latest,
    );
  }
}
