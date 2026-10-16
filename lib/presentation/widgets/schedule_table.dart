import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';

/// Гибридная таблица (Quiet + Timeline + Dense):
/// корпус и шапка — Dense, колонка времени с номером пары — Dense,
/// иконки преподавателя/кабинета — Timeline, таблетка кабинета
/// справа — Quiet (tealPale, скругление 999).
/// DRY: используется в просмотре, избранном и общем расписании.
final class ScheduleTable extends StatelessWidget {
  final List<Lesson> lessons;
  const ScheduleTable({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Пар нет', style: TextStyle(color: AppColors.inkLight)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.headerCell,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text('Время',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: Text('Предмет / Преподаватель',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 92,
                  child: Text('Кабинет',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          for (var i = 0; i < lessons.length; i++)
            _Row(
              lesson: lessons[i],
              striped: i.isOdd,
              isLast: i == lessons.length - 1,
            ),
        ],
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  final Lesson lesson;
  final bool striped;
  final bool isLast;
  const _Row({
    required this.lesson,
    required this.striped,
    required this.isLast,
  });

  List<String> _split(String s) =>
      s.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final rooms = _split(lesson.classroom);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: striped ? const Color(0xFFF7FAFA) : Colors.white,
        border: isLast
            ? null
            : Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Время + номер пары — как в Dense.
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withAlpha(22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lesson.order.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF356E6A),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.startTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                Text(
                  lesson.endTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Предмет + преподаватель — Quiet: одна строка "X / Y",
          // под ней одна строка преподавателей с иконкой.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                _TeacherLine(text: lesson.teacher),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Кабинет справа: одна таблетка Quiet. Иконка одна,
          // по центру слева; кабинеты стопкой справа.
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 14,
                      color: Color(0xFF356E6A),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < rooms.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : 2,
                              ),
                              child: Text(
                                rooms[i],
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF356E6A),
                                  height: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка преподавателя с иконкой (декоративна, смысл несёт текст).
final class _TeacherLine extends StatelessWidget {
  final String text;
  const _TeacherLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 14,
          color: AppColors.inkLight,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkLight,
            ),
          ),
        ),
      ],
    );
  }
}
