import 'package:rwkv_studio/src/models/common/app_component_update.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

class AppInfo extends Equatable {
  final List<AppComponentInfo> components;
  final AppComponentInfo app;
  final String updateUrl;

  @override
  List<Object?> get props => [components, app, updateUrl];

  const AppInfo({
    required this.components,
    required this.app,
    required this.updateUrl,
  });

  static const empty = AppInfo(
    components: [],
    app: AppComponentInfo.empty,
    updateUrl: '',
  );

  Map toJson() => {
    'components': components.map((c) => c.toJson()).toList(),
    'app': app.toJson(),
    'update_url': updateUrl,
  };

  factory AppInfo.fromJson(dynamic json) => AppInfo(
    components: (json['components'] as Iterable)
        .map((c) => AppComponentInfo.fromJson(c))
        .toList(),
    app: AppComponentInfo.fromJson(json['app']),
    updateUrl: json['update_url'] as String,
  );

  AppInfo copyWith({
    List<AppComponentInfo>? components,
    AppComponentInfo? app,
    String? updateUrl,
  }) {
    return AppInfo(
      components: components ?? this.components,
      app: app ?? this.app,
      updateUrl: updateUrl ?? this.updateUrl,
    );
  }
}
