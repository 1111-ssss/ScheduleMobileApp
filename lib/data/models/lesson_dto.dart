import '../../domain/entities/lesson.dart';

/// DTO одной пары. fromJson терпим к двум стилям ключей:
/// нашему seed (startTime/endTime/...) и возможному API-стилю.
final class LessonDto {
  final int order;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String classroom;

  const LessonDto({
    required this.order,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.classroom,
  });

  factory LessonDto.fromJson(Map<String, dynamic> j) => LessonDto(
        order: (j['order'] as num?)?.toInt() ?? 0,
        startTime: (j['startTime'] ?? j['start_time'] ?? j['timeStart'] ?? '')
            as String,
        endTime:
            (j['endTime'] ?? j['end_time'] ?? j['timeEnd'] ?? '') as String,
        subject: (j['subject'] ?? j['title'] ?? '') as String,
        teacher: (j['teacher'] ?? j['teacherName'] ?? '') as String,
        classroom: (j['classroom'] ?? j['room'] ?? j['cabinet'] ?? '') as String,
      );

  Lesson toEntity() => Lesson(
        order: order,
        startTime: startTime,
        endTime: endTime,
        subject: subject,
        teacher: teacher,
        classroom: classroom,
      );
}
