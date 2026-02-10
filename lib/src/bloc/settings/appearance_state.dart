part of 'setting_cubit.dart';

class AppearanceSettingState extends Equatable {
  static final lightTheme = FluentThemeData.light();
  static final darkTheme = FluentThemeData.dark();

  final FluentThemeData theme;
  final String fontFamily;
  final int fontSize;
  final UserType userType;

  @override
  List<Object?> get props => [theme, fontFamily, fontSize, userType];

  AppearanceSettingState({
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
    required this.userType,
  });

  factory AppearanceSettingState.initial() {
    return AppearanceSettingState(
      theme: AppearanceSettingState.lightTheme,
      fontFamily: 'Microsoft YaHei',
      fontSize: 16,
      userType: UserType.user,
    );
  }

  AppearanceSettingState copyWith({
    FluentThemeData? theme,
    String? fontFamily,
    int? fontSize,
    UserType? userType,
  }) {
    return AppearanceSettingState(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      userType: userType ?? this.userType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme == AppearanceSettingState.lightTheme ? 'light' : 'dark',
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'userType': userType.index,
    };
  }

  factory AppearanceSettingState.fromMap(dynamic map) {
    if (map == null) {
      return AppearanceSettingState.initial();
    }
    return AppearanceSettingState(
      theme: map['theme'] == 'light'
          ? AppearanceSettingState.lightTheme
          : AppearanceSettingState.darkTheme,
      fontFamily: map['fontFamily'] as String,
      fontSize: map['fontSize'] as int,
      userType: UserType.fromValue(map['userType']),
    );
  }
}
