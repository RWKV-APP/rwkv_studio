import 'package:rwkv_studio/src/models/settings/appearance_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/cache_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/mcp_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/model_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/python_settings_model.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

class AppSettingsModel extends Equatable {
  final ModelSettingsModel model;
  final AppearanceSettingsModel appearance;
  final CacheSettingsModel cache;
  final PythonSettingsModel python;
  final McpSettingsModel mcp;

  const AppSettingsModel({
    required this.model,
    required this.appearance,
    required this.cache,
    required this.python,
    required this.mcp,
  });

  factory AppSettingsModel.initial() {
    return AppSettingsModel(
      appearance: AppearanceSettingsModel.initial(),
      cache: CacheSettingsModel.initial(),
      model: ModelSettingsModel.initial(),
      python: PythonSettingsModel.initial(),
      mcp: McpSettingsModel.initial(),
    );
  }

  AppSettingsModel copyWith({
    AppearanceSettingsModel? appearance,
    CacheSettingsModel? cache,
    ModelSettingsModel? model,
    PythonSettingsModel? python,
    McpSettingsModel? mcp,
  }) {
    return AppSettingsModel(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      model: model ?? this.model,
      python: python ?? this.python,
      mcp: mcp ?? this.mcp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model.toMap(),
      'appearance': appearance.toMap(),
      'python': python.toMap(),
      'cache': cache.toMap(),
      'mcp': mcp.toMap(),
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return AppSettingsModel.initial();
    }
    return AppSettingsModel(
      model: ModelSettingsModel.fromMap(map['model']),
      appearance: AppearanceSettingsModel.fromMap(map['appearance']),
      cache: CacheSettingsModel.fromMap(map['cache']),
      python: PythonSettingsModel.fromMap(map['python']),
      mcp: McpSettingsModel.fromMap(map['mcp']),
    );
  }

  @override
  List<Object?> get props => [model, appearance, cache, python, mcp];
}
