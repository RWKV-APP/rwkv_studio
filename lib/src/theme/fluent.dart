import 'package:fluent_ui/fluent_ui.dart';

extension CustomeFluent on FluentThemeData {
  FluentThemeData custom({String? fontFamily}) {
    return copyWith(
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: Colors.transparent,
      ),
      typography: Typography.fromBrightness(brightness: brightness)
          .apply(fontFamily: fontFamily)
          .merge(
            Typography.raw(
              caption: TextStyle(fontSize: 10),
              subtitle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
      buttonTheme: ButtonThemeData(
        hyperlinkButtonStyle: ButtonStyle(
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
