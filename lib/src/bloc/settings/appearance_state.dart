part of 'setting_cubit.dart';

class AppearanceSettingState extends Equatable {
  static final lightTheme = FluentThemeData.light();
  static final darkTheme = FluentThemeData.dark();

  final FluentThemeData theme;
  final String fontFamily;
  final int fontSize;

  @override
  List<Object?> get props => [theme, fontFamily, fontSize];

  AppearanceSettingState({
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
  });

  factory AppearanceSettingState.initial() {
    return AppearanceSettingState(
      theme: AppearanceSettingState.lightTheme,
      fontFamily: 'Microsoft YaHei',
      fontSize: 16,
    );
  }

  AppearanceSettingState copyWith({
    FluentThemeData? theme,
    String? fontFamily,
    int? fontSize,
  }) {
    return AppearanceSettingState(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme == AppearanceSettingState.lightTheme ? 'light' : 'dark',
      'fontFamily': fontFamily,
      'fontSize': fontSize,
    };
  }

  factory AppearanceSettingState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return AppearanceSettingState.initial();
    }
    return AppearanceSettingState(
      theme: map['theme'] == 'light'
          ? AppearanceSettingState.lightTheme
          : AppearanceSettingState.darkTheme,
      fontFamily: map['fontFamily'] as String,
      fontSize: map['fontSize'] as int,
    );
  }
}
