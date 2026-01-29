import 'package:fluent_ui/fluent_ui.dart';

extension CustomeFluent on FluentThemeData {
  FluentThemeData custom({String? fontFamily}) {
    return copyWith(
      navigationPaneTheme: const NavigationPaneThemeData(
        backgroundColor: Colors.transparent,
      ),
      typography: Typography.fromBrightness(brightness: brightness)
          .apply(fontFamily: fontFamily)
          .merge(
            const Typography.raw(
              caption: TextStyle(fontSize: 10),
              subtitle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
        hyperlinkButtonStyle: const ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w500),
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
