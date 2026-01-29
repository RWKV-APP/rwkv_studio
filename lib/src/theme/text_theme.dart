import 'package:fluent_ui/fluent_ui.dart';

class AppTextStyle {
  AppTextStyle._();

  static final bodySecondary = TextStyle(fontSize: 14, color: Colors.grey[100]);
  static final body = const TextStyle(fontSize: 14);
  static final label = const TextStyle(fontSize: 12);
  static final bodyBold = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static final heading = const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static final headingL = const TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static final caption = const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1,
  );
  static final captionItalic = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
  );
}
