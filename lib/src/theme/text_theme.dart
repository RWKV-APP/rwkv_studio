import 'package:fluent_ui/fluent_ui.dart';

class AppTextStyle {
  AppTextStyle._();

  static final bodySecondary = TextStyle(fontSize: 14, color: Colors.grey[100]);
  static final body = TextStyle(fontSize: 14);
  static final label = TextStyle(fontSize: 12);
  static final bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static final heading = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static final headingL = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static final caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1,
  );
  static final captionItalic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
  );
}
