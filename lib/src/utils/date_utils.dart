extension DateUtils on DateTime {
  static final _today = DateTime.now();

  DateTime get dateOnly => DateTime(year, month, day);

  String get displayDateTime => '$month/$day $hour:$minute';

  String get dayMonthYearHourMinuteSecond =>
      '$day/$month/$year $hour:$minute:$second';

  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isToday() => isSameDate(_today);

  bool isYesterday() => isSameDate(_today.subtract(Duration(days: 1)));

  bool isThisYear() => year == _today.year;

  bool isThisMonth() => year == _today.year && month == _today.month;

  bool isThisWeek() {
    DateTime monday = _today;
    while (monday.weekday != DateTime.monday) {
      monday = monday.subtract(Duration(days: 1));
    }
    DateTime monday2 = this;
    while (monday2.weekday != DateTime.monday) {
      monday2 = monday2.subtract(Duration(days: 1));
    }
    return monday.isSameDate(monday2);
  }

  String get displayTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get displayDate {
    return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String get prettyDataTime {
    final now = DateTime.now();
    final difference = now.difference(this);
    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365} years ago';
    }
    if (difference.inDays > 5) {
      return displayDateTime;
    }
    if (difference.inDays > 1) {
      return '${difference.inDays}天前';
    }
    if (difference.inMinutes > 60) {
      if (difference.inHours > now.hour) {
        final n =
            {
              hour > 0: '凌晨',
              hour > 6: '早上',
              hour > 8: '上午',
              hour > 11: '中午',
              hour > 13: '下午',
              hour > 17: '傍晚',
              hour > 19: '晚上',
            }[true] ??
            '';
        return '昨天$n';
      }
      return '${difference.inHours}小时前';
    }
    if (difference.inMinutes > 1) {
      return '${difference.inMinutes}分钟前';
    }
    if (difference.inSeconds > 30) {
      return '${difference.inSeconds}秒前';
    }
    return '刚刚';
  }
}
