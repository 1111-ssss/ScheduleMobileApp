import '../models/day_schedule_dto.dart';

/// Абстракция транспортного уровня — контракт поверх эндпоинтов из ТЗ:
///   GET /api/data/teachers
///   GET /api/data/groups
///   GET Schedule/teacher/week | Schedule/teacher/day
///   GET Schedule/group/day   | Schedule/group/week
///   GET Schedule (полное расписание на день)
///
/// DIP: репозитории зависят от этого интерфейса.
/// Сейчас его реализует LocalJsonScheduleApi (seed из assets),
/// позже добавится HttpScheduleApi без изменения вызывающего кода.
abstract interface class ScheduleApi {
  Future<List<String>> getTeachers();
  Future<Map<String, List<String>>> getGroups();

  Future<List<DayScheduleDto>> getTeacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  });

  Future<DayScheduleDto?> getTeacherDay({
    required String teacher,
    required DateTime date,
  });

  Future<DayScheduleDto?> getGroupDay({
    required String group,
    required DateTime date,
  });

  Future<List<DayScheduleDto>> getGroupWeek({
    required String group,
    required DateTime from,
    required int days,
  });

  Future<List<DayScheduleDto>> getFullSchedule({required DateTime date});
}
