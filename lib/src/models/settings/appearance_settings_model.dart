import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

class AppearanceSettingsModel extends Equatable {
  static final lightTheme = FluentThemeData.light();
  static final darkTheme = FluentThemeData.dark();

  final FluentThemeData theme;
  final String fontFamily;
  final int fontSize;
  final UserType userType;

  @override
  List<Object?> get props => [theme, fontFamily, fontSize, userType];

  AppearanceSettingsModel({
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
    required this.userType,
  });

  factory AppearanceSettingsModel.initial() {
    return AppearanceSettingsModel(
      theme: AppearanceSettingsModel.lightTheme,
      fontFamily: 'NotoSansSC',
      fontSize: 16,
      userType: UserType.user,
    );
  }

  AppearanceSettingsModel copyWith({
    FluentThemeData? theme,
    String? fontFamily,
    int? fontSize,
    UserType? userType,
  }) {
    return AppearanceSettingsModel(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      userType: userType ?? this.userType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme == AppearanceSettingsModel.lightTheme ? 'light' : 'dark',
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'userType': userType.index,
    };
  }

  factory AppearanceSettingsModel.fromMap(dynamic map) {
    if (map == null) {
      return AppearanceSettingsModel.initial();
    }
    return AppearanceSettingsModel(
      theme: map['theme'] == 'light'
          ? AppearanceSettingsModel.lightTheme
          : AppearanceSettingsModel.darkTheme,
      fontFamily: map['fontFamily'] as String,
      fontSize: map['fontSize'] as int,
      userType: UserType.fromValue(map['userType']),
    );
  }
}
