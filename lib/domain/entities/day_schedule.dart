import 'package:flutter/foundation.dart';

import 'lesson.dart';

/// Расписание одного дня для одной группы/преподавателя.
/// Единая сущность на все эндпоинты Schedule/* (DRY):
/// день группы, день преподавателя и элемент полного расписания дня —
/// это один и тот же shape DayScheduleDTO.
@immutable
final class DaySchedule {
  final DateTime date;
  final String weekday;
  final String? group;
  final String? teacher;
  final List<Lesson> lessons;

  const DaySchedule({
    required this.date,
    required this.weekday,
    this.group,
    this.teacher,
    required this.lessons,
  });

  int get lessonsCount => lessons.length;

  /// "Группа Б21 [03.11]" — заголовок карточки из макета.
  String title({required bool isGroupMode}) {
    final dd = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    final owner = isGroupMode ? (group ?? '') : (teacher ?? '');
    final prefix = isGroupMode ? 'Группа ' : '';
    return '$prefix$owner [$dd]'.trim();
  }
}
