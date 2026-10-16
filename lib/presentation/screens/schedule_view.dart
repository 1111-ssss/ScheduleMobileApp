import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/day_schedule.dart';
import '../state/schedule_controller.dart';
import '../widgets/filter_bar.dart';
import '../widgets/group_schedule_card.dart';
import '../widgets/overlays.dart';
import '../widgets/schedule_table.dart';

/// Экран просмотра: фильтры + неделя/день + карточки групп.
/// Режимы из макетов:
///  - Неделя: секции "Понедельник [03.11]" с таблицами подряд;
///  - День: чипы дней + карточки "Группа Б21 [03.11]".
final class ScheduleView extends StatefulWidget {
  final ScheduleController controller;
  final VoidCallback onOpenFavorites;
  const ScheduleView(
      {super.key, required this.controller, required this.onOpenFavorites});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

final class _ScheduleViewState extends State<ScheduleView> {
  ScheduleController get c => widget.controller;

  /// Свёрнутые дни недели (ключи — api-даты). По умолчанию всё развернуто.
  final Set<String> _collapsedDays = {};

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (c.loadingDirectory) {
      return const Center(child: CircularProgressIndicator());
    }
    final isGroup = c.mode == ScheduleMode.group;
    final hasWeek = c.week.isNotEmpty;
    final dayIdx = hasWeek
        ? c.selectedDayIndex.clamp(0, c.week.length - 1)
        : 0;
    return RefreshIndicator(
      onRefresh: c.reloadWeek,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        children: [
          FilterBar(
            isGroupMode: isGroup,
            weekMode: c.weekMode,
            specialties: c.specialties.keys.toList(),
            selectedSpecialty: c.selectedSpecialty,
            groups: c.groupsOfSelected,
            selectedGroup: c.selectedGroup,
            teacherQuery: c.teacherQuery,
            teacherSuggestions: c.filteredTeachers
                .where((t) => t != c.selectedTeacher)
                .toList(),
            weekRangeLabel:
                DateUtilsX.weekRange(c.weekStart, 6),
            onSpecialty: c.selectSpecialty,
            onGroup: c.selectGroup,
            onTeacherQuery: c.setTeacherQuery,
            onTeacherPicked: c.selectTeacher,
            onViewMode: c.setWeekMode,
            onPrevWeek: () => c.shiftWeek(-7),
            onNextWeek: () => c.shiftWeek(7),
            days: hasWeek && !c.weekMode
                ? [for (final d in c.week) d.date]
                : null,
            selectedDayIndex: dayIdx,
            onSelectDay: hasWeek && !c.weekMode ? c.selectDay : null,
            onPickDate: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: c.selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2027),
              );
              if (d != null) c.pickDate(d);
            },
          ),
          if (!isGroup && c.selectedTeacher.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Преподаватель: ${c.selectedTeacher}',
                  style: const TextStyle(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          if (c.loadingWeek)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (c.week.isEmpty)
            _empty()
          else if (c.weekMode)
            ..._weekSections(context)
          else
            ..._daySections(context),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(c.error ?? 'Расписание не найдено',
                style: const TextStyle(color: AppColors.inkLight)),
            TextButton(
                onPressed: c.reloadWeek, child: const Text('Повторить')),
          ],
        ),
      );

  List<Widget> _weekSections(BuildContext context) {
    return [
      for (final d in c.week)
        _WeekDaySection(
          key: ValueKey('week-${c.mode.name}-${DateUtilsX.apiDate(d.date)}'),
          day: d,
          collapsed: _collapsedDays.contains(_dayKey(d.date)),
          onToggle: () => setState(() {
            final k = _dayKey(d.date);
            _collapsedDays.contains(k)
                ? _collapsedDays.remove(k)
                : _collapsedDays.add(k);
          }),
        ),
    ];
  }

  static String _dayKey(DateTime d) => DateUtilsX.apiDate(d);

  /// День: ТОЛЬКО выбранная группа/преподаватель.
  /// Чипы дней уже отрисованы внутри FilterBar (адаптивная строка).
  List<Widget> _daySections(BuildContext context) {
    final idx = c.selectedDayIndex.clamp(0, c.week.length - 1);
    final day = c.week[idx];
    return [
      GroupScheduleCard(
        key: ValueKey(
            'day-${c.mode.name}-${DateUtilsX.apiDate(day.date)}'),
        day: day,
        isGroupMode: c.mode == ScheduleMode.group,
        onFullSchedule: () => FullScheduleSheet.show(
            context, day.date, c.fullDay(day.date)),
      ),
    ];
  }
}

/// Секция дня на вкладке "Неделя": заголовок разворачивает/сворачивает
/// таблицу, как строки дней на вкладке "День".
final class _WeekDaySection extends StatelessWidget {
  final DaySchedule day;
  final bool collapsed;
  final VoidCallback onToggle;
  const _WeekDaySection({
    super.key,
    required this.day,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${day.weekday} [${DateUtilsX.shortDate(day.date)}]',
                      style: const TextStyle(
                          color: AppColors.tealDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('${day.lessonsCount} пары',
                      style: const TextStyle(
                          color: AppColors.inkLight, fontSize: 12)),
                  Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: AppColors.inkLight),
                ],
              ),
            ),
          ),
          if (!collapsed) ScheduleTable(lessons: day.lessons),
        ],
      );
}
