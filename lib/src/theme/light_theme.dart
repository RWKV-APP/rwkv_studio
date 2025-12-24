import 'package:flutter/material.dart';

import 'base_theme.dart';

/// Palette tailored for a calm, desktop-oriented aesthetic.
class OrbitColors {
  OrbitColors._();

  static const Color anchor = Color(0xFF44506A);
  static const Color primary = Color(0xFF5C77C8);
  static const Color secondary = Color(0xFFA4BFA7);
  static const Color accent = Color(0xFFE1B18A);
  static const Color canvas = Color(0xFFF2F3F7);
  static const Color panel = Color(0xFFE7E9F1);
  static const Color border = Color(0xFFB6BECD);
}

class LightTheme {
  LightTheme._();

  static ThemeData get themeData {
    final base = BaseTheme.themeData;
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: OrbitColors.primary,
      onPrimary: Colors.white,
      secondary: OrbitColors.secondary,
      onSecondary: OrbitColors.canvas,
      onPrimaryContainer: OrbitColors.canvas,
      error: const Color(0xFFD76A6A),
      errorContainer: const Color(0xFFF9C1C1),
      onErrorContainer: const Color(0xFF9C4D4D),
      onError: Colors.white,
      surface: OrbitColors.panel,
      onSurface: OrbitColors.anchor,
    );

    final textTheme = ThemeData.light().textTheme.apply(
      bodyColor: OrbitColors.anchor,
      displayColor: OrbitColors.anchor,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: OrbitColors.canvas,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: OrbitColors.canvas,
        foregroundColor: OrbitColors.anchor,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.4,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: OrbitColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.cardTheme.shape,
          side: BorderSide(color: OrbitColors.border),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: Colors.transparent,
        indicatorColor: OrbitColors.primary.withAlpha((255 * 0.08).round()),
        selectedIconTheme: const IconThemeData(size: 22),
        unselectedIconTheme: IconThemeData(
          size: 22,
          color: OrbitColors.anchor.withAlpha((255 * 0.6).round()),
        ),
        selectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: OrbitColors.anchor,
          letterSpacing: 0.6,
        ),
        unselectedLabelTextStyle: textTheme.bodySmall?.copyWith(
          color: OrbitColors.anchor.withAlpha((255 * 0.5).round()),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: OrbitColors.panel,
        indicatorColor: OrbitColors.primary.withAlpha((255 * 0.12).round()),
      ),
      iconTheme: base.iconTheme.copyWith(
        color: OrbitColors.anchor.withAlpha((255 * 0.8).round()),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: base.iconButtonTheme.style?.copyWith(
          iconColor: WidgetStateProperty.all(OrbitColors.anchor),
          overlayColor: WidgetStateProperty.all(
            OrbitColors.primary.withAlpha((255 * 0.05).round()),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return OrbitColors.border;
            }
            return OrbitColors.primary;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(OrbitColors.anchor),
          backgroundColor: WidgetStateProperty.all(OrbitColors.secondary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(OrbitColors.anchor),
          side: WidgetStateProperty.all(BorderSide(color: OrbitColors.border)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.all(OrbitColors.primary),
          overlayColor: WidgetStateProperty.all(
            OrbitColors.primary.withAlpha((255 * 0.06).round()),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: false,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: OrbitColors.anchor.withAlpha((255 * 0.6).round()),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: OrbitColors.anchor.withAlpha((255 * 0.4).round()),
        ),
        border: _outlineWith(
          base.inputDecorationTheme.border,
          side: BorderSide(color: OrbitColors.border),
        ),
        enabledBorder: _outlineWith(
          base.inputDecorationTheme.enabledBorder,
          side: BorderSide(color: OrbitColors.border),
        ),
        focusedBorder: _outlineWith(
          base.inputDecorationTheme.focusedBorder,
          side: BorderSide(color: OrbitColors.primary, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: OrbitColors.panel,
        labelStyle: textTheme.bodySmall,
        shape: _mergeRoundedShape(
          base.chipTheme.shape,
          side: BorderSide(color: OrbitColors.border),
        ),
        selectedColor: OrbitColors.primary.withAlpha((255 * 0.1).round()),
        secondarySelectedColor: OrbitColors.secondary.withAlpha(
          (255 * 0.15).round(),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: OrbitColors.border),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: OrbitColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: _mergeRoundedShape(
          base.dialogTheme.shape,
          side: BorderSide(color: OrbitColors.border),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: OrbitColors.anchor.withAlpha((255 * 0.6).round()),
        textColor: OrbitColors.anchor,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: _boxWith(
          base.tooltipTheme.decoration,
          color: OrbitColors.anchor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).round()),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      bannerTheme: base.bannerTheme.copyWith(
        backgroundColor: OrbitColors.panel,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: OrbitColors.anchor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: OrbitColors.primary,
        inactiveTrackColor: OrbitColors.border,
        thumbColor: OrbitColors.accent,
        overlayColor: OrbitColors.primary.withAlpha((255 * 0.1).round()),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        indicator: _boxWith(
          base.tabBarTheme.indicator,
          color: OrbitColors.primary.withAlpha((255 * 0.12).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: OrbitColors.anchor,
        labelStyle: textTheme.bodyMedium,
        unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
          color: OrbitColors.anchor.withAlpha((255 * 0.5).round()),
        ),
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        headingTextStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headingRowColor: WidgetStateProperty.all(
          OrbitColors.panel.withAlpha((255 * 0.7).round()),
        ),
        dataTextStyle: textTheme.bodySmall,
        decoration: _boxWith(
          base.dataTableTheme.decoration,
          border: Border.all(color: OrbitColors.border),
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
