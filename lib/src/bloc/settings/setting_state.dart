part of 'setting_cubit.dart';

class SettingState extends Equatable {
  final ModelSettingState model;
  final AppearanceSettingState appearance;
  final CacheSettingState cache;
  final PythonSettingState python;

  final bool initialized;

  @override
  List<Object?> get props => [model, appearance, cache, python, initialized];

  SettingState({
    required this.appearance,
    required this.cache,
    required this.model,
    required this.python,
    required this.initialized,
  });

  factory SettingState.initial() {
    return SettingState(
      appearance: AppearanceSettingState.initial(),
      cache: CacheSettingState.initial(),
      model: ModelSettingState.initial(),
      python: PythonSettingState.initial(),
      initialized: false,
    );
  }

  SettingState copyWith({
    AppearanceSettingState? appearance,
    CacheSettingState? cache,
    ModelSettingState? model,
    PythonSettingState? python,
    bool? initialized,
  }) {
    return SettingState(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      model: model ?? this.model,
      python: python ?? this.python,
      initialized: initialized ?? this.initialized,
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

  factory SettingState.fromMap(Map<String, dynamic> map) {
    return SettingState(
      model: ModelSettingState.fromMap(map['model']),
      appearance: AppearanceSettingState.fromMap(map['appearance']),
      cache: CacheSettingState.fromMap(map['cache']),
      initialized: true,
      python: PythonSettingState.fromMap(map['python']),
    );
  }
}
