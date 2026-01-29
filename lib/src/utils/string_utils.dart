extension DateTimeExtension on DateTime {
  String get dateString =>
      [year, month, day].map((e) => e.toString().padLeft(2, '0')).join('-');

  String get timeString =>
      [hour, minute, second].map((e) => e.toString().padLeft(2, '0')).join(':');

  String get datetimeString => '$dateString $timeString';
}

extension NumExtension on num {
  String get formatFileSize {
    if (this > 1024 * 1024 * 1024) {
      return '${(this / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
    } else {
      return '${(this / 1024 / 1024).toStringAsFixed(2)}MB';
    }
  }
}
