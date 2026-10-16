import 'package:flutter/foundation.dart';

/// Одна пара. Строки subject/teacher/classroom уже содержат
/// подгруппы как "X / Y" — так отдаёт бэкенд и так нарисовано в макете.
/// Отдельной модели подгрупп нет (YAGNI): если API уточнится,
/// поменяется только DTO-маппинг, сущность не тронем.
@immutable
final class Lesson {
  final int order;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String classroom;

  const Lesson({
    required this.order,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.classroom,
  });

  String get timeLabel => '$startTime\n$endTime';
}
