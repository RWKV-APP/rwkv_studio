import 'package:flutter/material.dart';

import 'base_theme.dart';

class NebulaColors {
  NebulaColors._();

  static const Color depth = Color(0xFF0F1624);
  static const Color surface = Color(0xFF1C2435);
  static const Color overlay = Color(0xFF272F43);
  static const Color primary = Color(0xFF8EA7FF);
  static const Color secondary = Color(0xFF6ECFC4);
  static const Color accent = Color(0xFFE4B777);
  static const Color border = Color(0xFF2F3952);
  static const Color textStrong = Color(0xFFE6E9F5);
  static const Color textMuted = Color(0xFFB3B9D3);
}

class DarkTheme {
  DarkTheme._();

  static ThemeData get themeData {
    final base = BaseTheme.themeData;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: NebulaColors.primary,
      onPrimary: NebulaColors.depth,
      secondary: NebulaColors.secondary,
      onSecondary: NebulaColors.depth,
      error: const Color(0xFFEF7F7F),
      onError: NebulaColors.depth,
      surface: NebulaColors.surface,
      onSurface: NebulaColors.textStrong,
    );

    final textTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'JetBrains Mono',
      bodyColor: NebulaColors.textStrong,
      displayColor: NebulaColors.textStrong,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: NebulaColors.depth,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: NebulaColors.depth,
        foregroundColor: NebulaColors.textStrong,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: NebulaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.cardTheme.shape,
          side: BorderSide(color: NebulaColors.border),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: Colors.transparent,
        indicatorColor: NebulaColors.primary.withAlpha((255 * 0.15).round()),
        selectedIconTheme: IconThemeData(color: NebulaColors.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: NebulaColors.textMuted,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: NebulaColors.textStrong,
          letterSpacing: 0.6,
        ),
        unselectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: NebulaColors.textMuted,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: NebulaColors.surface,
        indicatorColor: NebulaColors.primary.withAlpha((255 * 0.15).round()),
      ),
      iconTheme: base.iconTheme.copyWith(color: NebulaColors.textMuted),
      iconButtonTheme: IconButtonThemeData(
        style: base.iconButtonTheme.style?.copyWith(
          iconColor: WidgetStateProperty.all(NebulaColors.textStrong),
          overlayColor: WidgetStateProperty.all(
            NebulaColors.primary.withAlpha((255 * 0.08).round()),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return NebulaColors.border;
            }
            return NebulaColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(NebulaColors.depth),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(NebulaColors.secondary),
          foregroundColor: WidgetStateProperty.all(NebulaColors.depth),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(NebulaColors.textStrong),
          side: WidgetStateProperty.all(BorderSide(color: NebulaColors.border)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(NebulaColors.accent),
          overlayColor: WidgetStateProperty.all(
            NebulaColors.accent.withAlpha((255 * 0.15).round()),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: NebulaColors.overlay,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: NebulaColors.textMuted,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: NebulaColors.textMuted.withAlpha((255 * 0.7).round()),
        ),
        border: _outlineWith(
          base.inputDecorationTheme.border,
          side: BorderSide(color: NebulaColors.border),
        ),
        enabledBorder: _outlineWith(
          base.inputDecorationTheme.enabledBorder,
          side: BorderSide(color: NebulaColors.border),
        ),
        focusedBorder: _outlineWith(
          base.inputDecorationTheme.focusedBorder,
          side: BorderSide(color: NebulaColors.primary, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: NebulaColors.overlay,
        labelStyle: textTheme.bodySmall,
        shape: _mergeRoundedShape(
          base.chipTheme.shape,
          side: BorderSide(color: NebulaColors.border),
        ),
        selectedColor: NebulaColors.primary.withAlpha((255 * 0.15).round()),
        secondarySelectedColor: NebulaColors.secondary.withAlpha(
          (255 * 0.2).round(),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: NebulaColors.border),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: NebulaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.dialogTheme.shape,
          side: BorderSide(color: NebulaColors.border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: NebulaColors.textMuted,
        textColor: NebulaColors.textStrong,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: _boxWith(
          base.tooltipTheme.decoration,
          color: NebulaColors.overlay,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: NebulaColors.border),
        ),
        textStyle: textTheme.bodySmall,
      ),
      bannerTheme: base.bannerTheme.copyWith(
        backgroundColor: NebulaColors.overlay,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: NebulaColors.overlay,
        contentTextStyle: textTheme.bodyMedium,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: NebulaColors.primary,
        inactiveTrackColor: NebulaColors.border,
        thumbColor: NebulaColors.accent,
        overlayColor: NebulaColors.primary.withAlpha((255 * 0.1).round()),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        indicator: _boxWith(
          base.tabBarTheme.indicator,
          color: NebulaColors.primary.withAlpha((255 * 0.15).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: NebulaColors.textStrong,
        labelStyle: textTheme.bodyMedium,
        unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
          color: NebulaColors.textMuted,
        ),
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        headingTextStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        headingRowColor: WidgetStateProperty.all(NebulaColors.overlay),
        dataTextStyle: textTheme.bodySmall,
        decoration: _boxWith(
          base.dataTableTheme.decoration,
          border: Border.all(color: NebulaColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

RoundedRectangleBorder _mergeRoundedShape(
  ShapeBorder? baseShape, {
  BorderSide? side,
}) {
  final rounded = baseShape is RoundedRectangleBorder
      ? baseShape
      : const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
  return rounded.copyWith(side: side ?? rounded.side);
}

OutlineInputBorder _outlineWith(InputBorder? baseBorder, {BorderSide? side}) {
  final outline = baseBorder is OutlineInputBorder
      ? baseBorder
      : const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
  return outline.copyWith(borderSide: side ?? outline.borderSide);
}

Decoration _boxWith(
  Decoration? baseDecoration, {
  Color? color,
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  Border? border,
}) {
  final box = baseDecoration is BoxDecoration
      ? baseDecoration
      : const BoxDecoration();
  return box.copyWith(
    color: color ?? box.color,
    borderRadius: borderRadius ?? box.borderRadius,
    boxShadow: boxShadow ?? box.boxShadow,
    border: border ?? box.border,
  );
}
