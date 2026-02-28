import 'package:fluent_ui/fluent_ui.dart';

extension CustomeFluent on FluentThemeData {
  FluentThemeData custom({String? fontFamily}) {
    final defaultFontStyle = TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontFamily: fontFamily,
      fontVariations: [
        const FontVariation.weight(400),
        const FontVariation.width(100),
        const FontVariation.slant(-5),
      ],
    );

    return copyWith(
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: Colors.transparent,
      ),
      typography: Typography.fromBrightness(brightness: brightness)
          .apply(fontFamily: fontFamily)
          .merge(
            Typography.raw(
              body: defaultFontStyle,
              caption: defaultFontStyle.copyWith(fontSize: 10),
              subtitle: defaultFontStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      toggleButtonTheme: ToggleButtonThemeData(
        checkedButtonStyle: ButtonStyle(
          padding: const WidgetStatePropertyAll(.zero),
          foregroundColor: WidgetStatePropertyAll(activeColor),
          backgroundColor: WidgetStatePropertyAll(accentColor.dark),
        ),
        uncheckedButtonStyle: const ButtonStyle(
          padding: WidgetStatePropertyAll(.zero),
        ),
      ),
      buttonTheme: ButtonThemeData(
        outlinedButtonStyle: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          textStyle: WidgetStatePropertyAll(
            defaultFontStyle.copyWith(fontWeight: FontWeight.w500),
          ),
          foregroundColor: WidgetStatePropertyAll(accentColor),
        ),
        hyperlinkButtonStyle: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            defaultFontStyle.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        defaultButtonStyle: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          textStyle: buttonTheme.defaultButtonStyle?.textStyle,
        ),
        iconButtonStyle: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        filledButtonStyle: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }
}
