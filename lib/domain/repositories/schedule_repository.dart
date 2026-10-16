import '../entities/day_schedule.dart';

/// Расписание. Сигнатуры 1-в-1 повторяют эндпоинты бэкенда
/// (Schedule/teacher/week, .../day, group/..., GET Schedule).
/// Presentation зависит только от этого интерфейса (DIP).
abstract interface class ScheduleRepository {
  Future<List<DaySchedule>> groupWeek({
    required String group,
    required DateTime from,
    required int days,
  });

  Future<DaySchedule?> groupDay({required String group, required DateTime date});

  Future<List<DaySchedule>> teacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  });

  Future<DaySchedule?> teacherDay({
    required String teacher,
    required DateTime date,
  });

  /// Полное расписание на день: по одному DaySchedule на группу.
  Future<List<DaySchedule>> fullDay({required DateTime date});
}
