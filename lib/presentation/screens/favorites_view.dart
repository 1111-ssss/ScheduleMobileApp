import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/day_schedule.dart';
import '../../domain/entities/favorite.dart';
import '../state/favorites_controller.dart';
import '../state/schedule_controller.dart';
import '../widgets/filter_bar.dart';
import '../widgets/menu_and_dialog.dart';
import '../widgets/schedule_table.dart';

/// Экран избранного по макету: кнопка добавления, Неделя/День,
/// карточка цели с "Удалить", дни-строки "Понедельник [03.11] 4 пары".
final class FavoritesView extends StatefulWidget {
  final FavoritesController controller;
  final ScheduleController schedule;
  const FavoritesView(
      {super.key, required this.controller, required this.schedule});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

final class _FavoritesViewState extends State<FavoritesView> {
  FavoritesController get c => widget.controller;
  final Set<String> _collapsedFav = {};
  /// Общий выбранный день в режиме "День" — один на все избранные,
  /// чипы рисуются сверху, как на странице просмотра.
  int _selectedDay = (DateTime.now().weekday - 1);

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
    final addButton = ElevatedButton(
      onPressed: _addDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Добавить в избранное'),
    );
    final toggle = _ViewToggle(
        weekMode: c.weekMode, onChanged: c.setWeekMode);
    final weekNav = _WeekNav(
      label: DateUtilsX.weekRange(c.weekStart, 6),
      onPrev: () => c.shiftWeek(-7),
      onNext: () => c.shiftWeek(7),
      onPick: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: c.weekStart,
          firstDate: DateTime(2024),
          lastDate: DateTime(2027),
        );
        if (d != null) c.pickDate(d);
      },
    );
    return ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // WeekNav всегда справа у toggle; на узком — кнопка
              // в полную ширину, навигация строкой ниже.
              if (constraints.maxWidth >= 560) {
                return Row(
                  children: [
                    Expanded(child: addButton),
                    const SizedBox(width: 8),
                    weekNav,
                    const SizedBox(width: 8),
                    toggle,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  addButton,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      weekNav,
                      const SizedBox(width: 8),
                      toggle,
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          if (c.loading)
            const Center(child: CircularProgressIndicator())
          else if (c.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('В избранном пока пусто',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkLight)),
            )
          else ...[
            // В режиме "День" день выбирается один раз сверху
            // и применяется ко всем избранным сразу.
            if (!c.weekMode && _chipDays().isNotEmpty) ...[
              DayChips(
                days: _chipDays(),
                selected: _selectedDay.clamp(0, _chipDays().length - 1),
                onSelect: (i) => setState(() => _selectedDay = i),
              ),
              const SizedBox(height: 4),
            ],
            for (final f in c.items) _favoriteBlock(f),
          ],
        ],
      );
  }

  /// Дни для общих чипов: берём из первого избранного, у которого
  /// загружена неделя (все грузятся с одного weekStart, даты совпадают).
  List<DateTime> _chipDays() {
    for (final f in c.items) {
      final days = c.weeks[f.id] ?? const [];
      if (days.isNotEmpty) return [for (final d in days) d.date];
    }
    return const [];
  }

  DateTime? _selectedDate() {
    final days = _chipDays();
    if (days.isEmpty) return null;
    return days[_selectedDay.clamp(0, days.length - 1)];
  }

  Widget _favoriteBlock(Favorite f) {
    final days = c.weeks[f.id] ?? const [];
    // На вкладке "Неделя" вся карточка избранного сворачивается целиком.
    final favCollapsed = c.weekMode && _collapsedFav.contains(f.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: c.weekMode
                ? () => setState(() => _collapsedFav.contains(f.id)
                    ? _collapsedFav.remove(f.id)
                    : _collapsedFav.add(f.id))
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tealPale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(f.label,
                        style: const TextStyle(
                            color: AppColors.tealDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                  if (c.weekMode)
                    Icon(
                        favCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: AppColors.tealDark),
                  GestureDetector(
                    onTap: () => c.remove(f.id),
                    child: Container(
                      constraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Удалить',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!favCollapsed) ...[
            const SizedBox(height: 6),
            if (days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Расписание не найдено',
                    style: TextStyle(color: AppColors.inkLight)),
              )
            else if (c.weekMode)
              for (final d in days) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      '${d.weekday} [${DateUtilsX.shortDate(d.date)}]',
                      style: const TextStyle(
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                ScheduleTable(lessons: d.lessons),
              ]
            else
              _favSelectedDay(f),
          ],
        ],
      ),
    );
  }

  /// Режим "День": таблица общего выбранного дня для этого избранного.
  /// День ищется по дате — если у цели нет пар в этот день, так и пишем.
  Widget _favSelectedDay(Favorite f) {
    final selected = _selectedDate();
    if (selected == null) return const SizedBox.shrink();
    final days = c.weeks[f.id] ?? const [];
    DaySchedule? match;
    for (final d in days) {
      if (d.date.year == selected.year &&
          d.date.month == selected.month &&
          d.date.day == selected.day) {
        match = d;
        break;
      }
    }
    if (match == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Нет пар в этот день',
            style: TextStyle(color: AppColors.inkLight, fontSize: 12)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            '${match.weekday} [${DateUtilsX.shortDate(match.date)}]',
            style: const TextStyle(
                color: AppColors.tealDark, fontWeight: FontWeight.w600),
          ),
        ),
        ScheduleTable(lessons: match.lessons),
      ],
    );
  }

  Future<void> _addDialog() async {
    final s = widget.schedule;
    final result = await showDialog<Favorite>(
      context: context,
      builder: (_) => AddFavoriteDialog(
        specialties: s.specialties.keys.toList(),
        initialSpecialty: s.selectedSpecialty,
        groups: s.groupsOfSelected,
        teachers: s.teachers,
      ),
    );
    if (result != null) c.add(result);
  }
}

final class _ViewToggle extends StatelessWidget {
  final bool weekMode;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.weekMode, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active, VoidCallback tap) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            active ? Colors.white : AppColors.ink)),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.tealPale,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Неделя', weekMode, () => onChanged(true)),
          seg('День', !weekMode, () => onChanged(false)),
        ],
      ),
    );
  }
}

final class _WeekNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;
  const _WeekNav(
      {required this.label,
      required this.onPrev,
      required this.onNext,
      required this.onPick});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.tealPale,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onPrev,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.chevron_left,
                        size: 20, color: Color(0xFF356E6A),
                        semanticLabel: 'Предыдущая неделя'),
                  )),
            ),
            GestureDetector(
              onTap: onPick,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                child: Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF356E6A),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    const Icon(Icons.calendar_month_outlined,
                        size: 18, color: Color(0xFF356E6A),
                        semanticLabel: 'Выбрать дату'),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onNext,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.chevron_right,
                        size: 20, color: Color(0xFF356E6A),
                        semanticLabel: 'Следующая неделя'),
                  )),
            ),
          ],
        ),
      );
}
