import 'package:flutter/material.dart';

class BaseTheme {
  BaseTheme._();

  static ThemeData get themeData {
    const radius = BorderRadius.all(Radius.circular(8));

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'NotoSansSC',
      fontFamilyFallback: [
        'Microsoft YaHei',
        'Bahnschrift',
        'Century Gothic',
        "Sarasa Mono SC",
        "PingFang SC",
        ".AppleSystemUIFont",
        'miui',
        'mipro',
      ],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 52,
        titleSpacing: 12,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        labelType: NavigationRailLabelType.all,
        groupAlignment: -1,
        indicatorShape: RoundedRectangleBorder(borderRadius: radius),
        useIndicator: true,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(borderRadius: radius),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 10,
        minVerticalPadding: 6,
        shape: RoundedRectangleBorder(borderRadius: radius),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      buttonTheme: const ButtonThemeData(
        height: 40,
        minWidth: 120,
        layoutBehavior: ButtonBarLayoutBehavior.padded,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size(140, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(140, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(140, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      iconTheme: const IconThemeData(size: 18),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
          minimumSize: WidgetStateProperty.all(const Size.square(36)),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        alignLabelWithHint: true,
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      badgeTheme: const BadgeThemeData(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        smallSize: 18,
        largeSize: 28,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(horizontal: 16),
        indicator: BoxDecoration(borderRadius: radius),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        dividerThickness: 0.4,
      ),
      dividerTheme: const DividerThemeData(thickness: 1, space: 24),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        splashRadius: 18,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      radioTheme: const RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: const SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        trackOutlineWidth: WidgetStatePropertyAll(1.2),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        waitDuration: const Duration(milliseconds: 250),
        showDuration: const Duration(seconds: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: const DialogThemeData(
        insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      bannerTheme: const MaterialBannerThemeData(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: radius),
        collapsedShape: RoundedRectangleBorder(borderRadius: radius),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }
}
