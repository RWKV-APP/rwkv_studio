import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

extension CustomeFluent on FluentThemeData {
  FluentThemeData custom({String? fontFamily}) {
    final isDark = brightness == Brightness.dark;
    final textColor = brightness == Brightness.light
        ? Colors.black
        : Colors.grey[60];

    final defaultFontStyle = TextStyle(
      fontSize: 14,
      color: textColor,
      fontFamily: fontFamily,
      fontVariations: [
        const FontVariation.weight(400),
        const FontVariation.width(100),
        const FontVariation.slant(-5),
      ],
    );

    return copyWith(
      extensions: [
        GptMarkdownThemeData(
          brightness: brightness,
          hrLineThickness: .5,
          hrLineColor: Colors.grey[100],
          h1: defaultFontStyle.copyWith(fontSize: 24, height: 2),
          h2: defaultFontStyle.copyWith(fontSize: 22, height: 1.8),
          h3: defaultFontStyle.copyWith(fontSize: 20),
          h4: defaultFontStyle.copyWith(fontSize: 18),
          h5: defaultFontStyle.copyWith(fontSize: 16),
        ),
      ],
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
          textStyle: WidgetStatePropertyAll(
            defaultFontStyle.copyWith(fontWeight: FontWeight.w500),
          ),
          foregroundColor: !isDark
              ? null
              : WidgetStateColor.fromMap({WidgetState.any: Colors.grey[40]}),
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
          foregroundColor: !isDark
              ? null
              : WidgetStateColor.fromMap({WidgetState.any: Colors.grey[40]}),
          textStyle: WidgetStatePropertyAll(
            defaultFontStyle.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
