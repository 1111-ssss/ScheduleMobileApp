import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/day_schedule.dart';
import 'schedule_table.dart';

/// Блок дня "Группа Б21 [08.11]" с кнопкой "Общее расписание".
/// Не сворачивается: на вкладке "День" таблица видна всегда.
final class GroupScheduleCard extends StatelessWidget {
  final DaySchedule day;
  final bool isGroupMode;
  final VoidCallback onFullSchedule;

  const GroupScheduleCard({
    super.key,
    required this.day,
    required this.isGroupMode,
    required this.onFullSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  day.title(isGroupMode: isGroupMode),
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              _PillButton(
                label: 'Общее расписание',
                onTap: onFullSchedule,
              ),
            ],
          ),
        ),
        ScheduleTable(lessons: day.lessons),
      ],
    );
  }
}

final class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
      );
}
