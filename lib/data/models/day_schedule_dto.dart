import '../../core/utils/date_utils.dart';
import '../../domain/entities/day_schedule.dart';
import 'lesson_dto.dart';

/// DTO дня — зеркало DayScheduleDTO бэкенда.
final class DayScheduleDto {
  final String date;
  final String weekday;
  final String? group;
  final String? teacher;
  final List<LessonDto> lessons;

  const DayScheduleDto({
    required this.date,
    required this.weekday,
    this.group,
    this.teacher,
    required this.lessons,
  });

  factory DayScheduleDto.fromJson(Map<String, dynamic> j) => DayScheduleDto(
        date: j['date'] as String,
        weekday: (j['weekday'] ?? j['dayOfWeek'] ?? '') as String,
        group: j['group'] as String?,
        teacher: j['teacher'] as String?,
        lessons: ((j['lessons'] ?? j['pairs'] ?? []) as List)
            .map((e) => LessonDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DaySchedule toEntity() => DaySchedule(
        date: DateUtilsX.parseApiDate(date),
        weekday: weekday,
        group: group,
        teacher: teacher,
        lessons: lessons.map((e) => e.toEntity()).toList(),
      );
}
