part of 'setting_cubit.dart';

class SettingState extends Equatable {
  final ServiceSettingState service;
  final AppearanceSettingState appearance;
  final CacheSettingState cache;

  final bool initialized;

  @override
  List<Object?> get props => [service, appearance, cache, initialized];

  SettingState({
    required this.appearance,
    required this.cache,
    required this.service,
    required this.initialized,
  });

  factory SettingState.initial() {
    return SettingState(
      appearance: AppearanceSettingState.initial(),
      cache: CacheSettingState.initial(),
      service: ServiceSettingState.initial,
      initialized: false,
    );
  }

  SettingState copyWith({
    AppearanceSettingState? appearance,
    CacheSettingState? cache,
    ServiceSettingState? service,
    bool? initialized,
  }) {
    return SettingState(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      service: service ?? this.service,
      initialized: initialized ?? this.initialized,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service': service.toMap(),
      'appearance': appearance.toMap(),
      'cache': cache.toMap(),
    };
  }

  factory SettingState.fromMap(Map<String, dynamic> map) {
    return SettingState(
      service: ServiceSettingState.fromMap(map['service']),
      appearance: AppearanceSettingState.fromMap(map['appearance']),
      cache: CacheSettingState.fromMap(map['cache']),
      initialized: true,
    );
  }
}
