/// Мелкие date-хелперы без intl, чтобы не тянуть зависимость ради YAGNI.
abstract final class DateUtilsX {
  static const _weekdays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  static const _monthsGenitive = [
    '',
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

  /// 03.11
  static String shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  /// 2025-11-03 (формат API).
  static String apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseApiDate(String s) => DateTime.parse(s);

  /// 04.11.2025 (вторник)
  static String fullTitle(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '(${weekdayName(d).toLowerCase()})';

  /// Понедельник недели, содержащей [d].
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  /// Диапазон недели для шапки: 03.11–08.11
  static String weekRange(DateTime monday, int days) {
    final end = monday.add(Duration(days: days - 1));
    return '${shortDate(monday)}–${shortDate(end)}';
  }

  static String monthYear(DateTime d) =>
      '${_monthsGenitive[d.month]} ${d.year}';
}
