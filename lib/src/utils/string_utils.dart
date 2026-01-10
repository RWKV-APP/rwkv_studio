extension DateTimeExtension on DateTime {
  String get dateString =>
      [year, month, day].map((e) => e.toString().padLeft(2, '0')).join('-');

  String get timeString =>
      [hour, minute, second].map((e) => e.toString().padLeft(2, '0')).join(':');

  String get datetimeString => '$dateString $timeString';
}
