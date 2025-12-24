import 'package:flutter/material.dart';

import 'base_theme.dart';

class VoidColors {
  VoidColors._();

  static const Color abyss = Color(0xFF000000);
  static const Color depth = Color(0xFF0B0B0B);
  static const Color outline = Color(0xFF1C1C1C);
  static const Color primary = Color(0xFF50B5FF);
  static const Color secondary = Color(0xFFFF8F5C);
  static const Color accent = Color(0xFF8EFFB1);
  static const Color textStrong = Color(0xFFE7EEF9);
  static const Color textMuted = Color(0xFF9DA7C0);
}

class BlackTheme {
  BlackTheme._();

  static ThemeData get themeData {
    final base = BaseTheme.themeData;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: VoidColors.primary,
      onPrimary: VoidColors.abyss,
      secondary: VoidColors.secondary,
      onSecondary: VoidColors.abyss,
      error: const Color(0xFFFF6A6A),
      onError: VoidColors.abyss,
      background: VoidColors.abyss,
      onBackground: VoidColors.textStrong,
      surface: VoidColors.depth,
      onSurface: VoidColors.textStrong,
    );

    final textTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'JetBrains Mono',
      bodyColor: VoidColors.textStrong,
      displayColor: VoidColors.textStrong,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: VoidColors.abyss,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: VoidColors.abyss,
        foregroundColor: VoidColors.textStrong,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: VoidColors.depth,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.cardTheme.shape,
          side: BorderSide(color: VoidColors.outline),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: Colors.transparent,
        indicatorColor: VoidColors.primary.withAlpha((255 * 0.2).round()),
        selectedIconTheme: IconThemeData(color: VoidColors.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: VoidColors.textMuted,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: VoidColors.textStrong,
        ),
        unselectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: VoidColors.textMuted,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: VoidColors.depth,
        indicatorColor: VoidColors.primary.withAlpha((255 * 0.18).round()),
      ),
      iconTheme: base.iconTheme.copyWith(color: VoidColors.textMuted),
      iconButtonTheme: IconButtonThemeData(
        style: base.iconButtonTheme.style?.copyWith(
          iconColor: WidgetStateProperty.all(VoidColors.textStrong),
          overlayColor: WidgetStateProperty.all(
            VoidColors.primary.withAlpha((255 * 0.2).round()),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return VoidColors.outline;
            }
            return VoidColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(VoidColors.abyss),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(VoidColors.secondary),
          foregroundColor: WidgetStateProperty.all(VoidColors.abyss),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(VoidColors.textStrong),
          side: WidgetStateProperty.all(BorderSide(color: VoidColors.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(VoidColors.accent),
          overlayColor: WidgetStateProperty.all(
            VoidColors.accent.withAlpha((255 * 0.2).round()),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: VoidColors.depth,
        labelStyle: textTheme.bodyMedium?.copyWith(color: VoidColors.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: VoidColors.textMuted.withAlpha((255 * 0.7).round()),
        ),
        border: _outlineWith(
          base.inputDecorationTheme.border,
          side: BorderSide(color: VoidColors.outline),
        ),
        enabledBorder: _outlineWith(
          base.inputDecorationTheme.enabledBorder,
          side: BorderSide(color: VoidColors.outline),
        ),
        focusedBorder: _outlineWith(
          base.inputDecorationTheme.focusedBorder,
          side: BorderSide(color: VoidColors.primary, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: VoidColors.depth,
        labelStyle: textTheme.bodySmall,
        shape: _mergeRoundedShape(
          base.chipTheme.shape,
          side: BorderSide(color: VoidColors.outline),
        ),
        selectedColor: VoidColors.primary.withAlpha((255 * 0.2).round()),
        secondarySelectedColor: VoidColors.secondary.withAlpha(
          (255 * 0.2).round(),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: VoidColors.outline),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: VoidColors.depth,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.dialogTheme.shape,
          side: BorderSide(color: VoidColors.outline),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: VoidColors.textMuted,
        textColor: VoidColors.textStrong,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: _boxWith(
          base.tooltipTheme.decoration,
          color: VoidColors.depth,
          border: Border.all(color: VoidColors.outline),
        ),
        textStyle: textTheme.bodySmall,
      ),
      bannerTheme: base.bannerTheme.copyWith(
        backgroundColor: VoidColors.depth,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: VoidColors.depth,
        contentTextStyle: textTheme.bodyMedium,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: VoidColors.primary,
        inactiveTrackColor: VoidColors.outline,
        thumbColor: VoidColors.accent,
        overlayColor: VoidColors.primary.withAlpha((255 * 0.2).round()),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        indicator: _boxWith(
          base.tabBarTheme.indicator,
          color: VoidColors.primary.withAlpha((255 * 0.18).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: VoidColors.textStrong,
        labelStyle: textTheme.bodyMedium,
        unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
          color: VoidColors.textMuted,
        ),
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        headingTextStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headingRowColor: WidgetStateProperty.all(VoidColors.depth),
        dataTextStyle: textTheme.bodySmall,
        decoration: _boxWith(
          base.dataTableTheme.decoration,
          border: Border.all(color: VoidColors.outline),
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
