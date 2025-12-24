import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/theme/base_theme.dart';
import 'package:rwkv_studio/src/theme/black_theme.dart';
import 'package:rwkv_studio/src/theme/dark_theme.dart';
import 'package:rwkv_studio/src/theme/light_theme.dart';

export 'text_theme.dart';

extension ThemeModeExt on BuildContext {
  ThemeData get theme => Theme.of(this);
}

class AppTheme {
  AppTheme._();

  static final light = LightTheme.themeData;
  static final dark = DarkTheme.themeData;
  static final black = BlackTheme.themeData;

  static ThemeData fromSeed(Color seed) {
    return BaseTheme.themeData.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      scaffoldBackgroundColor: HSLColor.fromColor(
        seed,
      ).withLightness(0.95).toColor(),
    );
  }
}
