import 'package:rwkv_studio/src/models/settings/appearance_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/cache_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/model_settings_model.dart';
import 'package:rwkv_studio/src/models/settings/python_settings_model.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

class AppSettingsModel extends Equatable {
  final ModelSettingsModel model;
  final AppearanceSettingsModel appearance;
  final CacheSettingsModel cache;
  final PythonSettingsModel python;

  const AppSettingsModel({
    required this.model,
    required this.appearance,
    required this.cache,
    required this.python,
  });

  factory AppSettingsModel.initial() {
    return AppSettingsModel(
      appearance: AppearanceSettingsModel.initial(),
      cache: CacheSettingsModel.initial(),
      model: ModelSettingsModel.initial(),
      python: PythonSettingsModel.initial(),
    );
  }

  AppSettingsModel copyWith({
    AppearanceSettingsModel? appearance,
    CacheSettingsModel? cache,
    ModelSettingsModel? model,
    PythonSettingsModel? python,
  }) {
    return AppSettingsModel(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      model: model ?? this.model,
      python: python ?? this.python,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model.toMap(),
      'appearance': appearance.toMap(),
      'python': python.toMap(),
      'cache': cache.toMap(),
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      model: ModelSettingsModel.fromMap(map['model']),
      appearance: AppearanceSettingsModel.fromMap(map['appearance']),
      cache: CacheSettingsModel.fromMap(map['cache']),
      python: PythonSettingsModel.fromMap(map['python']),
    );
  }

  @override
  List<Object?> get props => [model, appearance, cache, python];
}
