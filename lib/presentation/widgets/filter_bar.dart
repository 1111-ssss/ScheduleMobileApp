import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

/// Панель фильтров, гибрид Quiet: дропдауны в полную ширину (48px,
/// видимые лейблы), второй ряд — навигация по неделе слева
/// (стрелки + диапазон + datepicker-календарь), toggle Неделя/День справа.
/// В режиме преподавателя вместо дропдаунов — строка поиска.
/// В режиме "День" чипы дней адаптивные: на узком экране — строкой ниже,
/// на широком — в свободном месте той же строки между WeekNav и toggle
/// (скролл, если влезает только пара дней).
final class FilterBar extends StatelessWidget {
  final bool isGroupMode;
  final bool weekMode;
  final List<String> specialties;
  final String? selectedSpecialty;
  final List<String> groups;
  final String? selectedGroup;
  final String teacherQuery;
  final List<String> teacherSuggestions;
  final String weekRangeLabel;
  final ValueChanged<String?> onSpecialty;
  final ValueChanged<String?> onGroup;
  final ValueChanged<String> onTeacherQuery;
  final ValueChanged<String> onTeacherPicked;
  final ValueChanged<bool> onViewMode;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onPickDate;
  final List<DateTime>? days;
  final int selectedDayIndex;
  final ValueChanged<int>? onSelectDay;

  const FilterBar({
    super.key,
    required this.isGroupMode,
    required this.weekMode,
    required this.specialties,
    required this.selectedSpecialty,
    required this.groups,
    required this.selectedGroup,
    required this.teacherQuery,
    required this.teacherSuggestions,
    required this.weekRangeLabel,
    required this.onSpecialty,
    required this.onGroup,
    required this.onTeacherQuery,
    required this.onTeacherPicked,
    required this.onViewMode,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onPickDate,
    this.days,
    this.selectedDayIndex = 0,
    this.onSelectDay,
  });

  bool get _showDays =>
      !weekMode && days != null && days!.isNotEmpty && onSelectDay != null;

  @override
  Widget build(BuildContext context) {
    final weekNav = _WeekNav(
      label: weekRangeLabel,
      onPrev: onPrevWeek,
      onNext: onNextWeek,
      onPick: onPickDate,
    );
    final toggle =
        _ViewToggle(weekMode: weekMode, onChanged: onViewMode);
    return Column(
      children: [
        Row(
          children: [
            if (isGroupMode) ...[
              Expanded(
                child: _Drop(
                  label: 'Специальность',
                  value: selectedSpecialty,
                  items: specialties,
                  onChanged: onSpecialty,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop(
                  label: 'Группа',
                  value: selectedGroup,
                  items: groups,
                  onChanged: onGroup,
                ),
              ),
            ] else
              Expanded(child: _TeacherSearch(
                query: teacherQuery,
                suggestions: teacherSuggestions,
                onChanged: onTeacherQuery,
                onPicked: onTeacherPicked,
              )),
          ],
        ),
        const SizedBox(height: 10),
        if (!_showDays)
          // Неделя всегда справа, вплотную к toggle, на любой ширине.
          Row(
            children: [
              const Spacer(),
              weekNav,
              const SizedBox(width: 8),
              toggle,
            ],
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Дни остаются в той же строке, пока под них есть место
              // хотя бы на два чипа (~150px). WeekNav всегда справа
              // у toggle; дни — в свободном месте слева со скроллом.
              final chips = DayChips(
                days: days!,
                selected: selectedDayIndex.clamp(0, days!.length - 1),
                onSelect: onSelectDay!,
              );
              const rightCluster = 200 + 130 + 16;
              final inline =
                  constraints.maxWidth - rightCluster >= 150;
              if (!inline) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        weekNav,
                        const SizedBox(width: 8),
                        toggle,
                      ],
                    ),
                    const SizedBox(height: 8),
                    chips,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: chips),
                  const SizedBox(width: 8),
                  weekNav,
                  const SizedBox(width: 8),
                  toggle,
                ],
              );
            },
          ),
      ],
    );
  }
}

final class _Drop extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Drop(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkLight)),
                value: items.contains(value) ? value : null,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.ink),
                items: [
                  for (final i in items)
                    DropdownMenuItem(value: i, child: Text(i)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
}

/// Поиск преподавателя. Stateful: контроллер живёт в состоянии,
/// иначе пересоздание TextEditingController в build сбрасывало ввод/фокус
/// при каждом notifyListeners (это и был баг "ничего не находится").
final class _TeacherSearch extends StatefulWidget {
  final String query;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPicked;
  const _TeacherSearch(
      {required this.query,
      required this.suggestions,
      required this.onChanged,
      required this.onPicked});

  @override
  State<_TeacherSearch> createState() => _TeacherSearchState();
}

final class _TeacherSearchState extends State<_TeacherSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _TeacherSearch old) {
    super.didUpdateWidget(old);
    // Внешний сброс (выбор преподавателя чистит query) — отражаем в поле.
    if (old.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return;
    // Точное совпадение — выбираем сразу; иначе первый подходящий вариант.
    final exact = widget.suggestions.where((s) => s.toLowerCase() == q);
    final pick =
        exact.isNotEmpty ? exact.first : widget.suggestions.firstOrNull;
    if (pick != null) widget.onPicked(pick);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Преподаватель',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Поиск преподавателя...',
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppColors.inkLight),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _controller.text.isNotEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      onPressed: _submit,
                    ),
            ),
          ),
          if (widget.query.trim().isNotEmpty &&
              widget.suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal.withAlpha(120)),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final s in widget.suggestions.take(6))
                    ListTile(
                      dense: true,
                      title: Text(s, style: const TextStyle(fontSize: 13)),
                      onTap: () => widget.onPicked(s),
                    ),
                ],
              ),
            ),
        ],
      );
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
        decoration: BoxDecoration(
          color: AppColors.tealPale,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrow(Icons.chevron_left, onPrev, 'Предыдущая неделя'),
            GestureDetector(
              onTap: onPick,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF356E6A),
                        fontWeight: FontWeight.w700)),
              ),
            ),
            // Datepicker: отдельная кнопка-календарь 44px.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.calendar_month_outlined,
                      size: 18, color: Color(0xFF356E6A),
                      semanticLabel: 'Выбрать дату'),
                ),
              ),
            ),
            _arrow(Icons.chevron_right, onNext, 'Следующая неделя'),
          ],
        ),
      );

  Widget _arrow(IconData icon, VoidCallback tap, String hint) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: const Color(0xFF356E6A),
                semanticLabel: hint),
          ),
        ),
      );
}

const _shortDays = {
  'Понедельник': 'Пн',
  'Вторник': 'Вт',
  'Среда': 'Ср',
  'Четверг': 'Чт',
  'Пятница': 'Пт',
  'Суббота': 'Сб',
  'Воскресенье': 'Вс',
};

/// Чипы дня, Dense-компакт слева: короткое имя + дата, без счётчика пар.
/// Скроллбар всегда чуть виден (хинт скролла).
final class DayChips extends StatefulWidget {
  final List<DateTime> days;
  final int selected;
  final ValueChanged<int> onSelect;
  const DayChips(
      {super.key,
      required this.days,
      required this.selected,
      required this.onSelect});

  @override
  State<DayChips> createState() => _DayChipsState();
}

final class _DayChipsState extends State<DayChips> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 62,
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          thickness: 4,
          radius: const Radius.circular(2),
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: widget.days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final d = widget.days[i];
              final active = i == widget.selected;
              final name =
                  _shortDays[DateUtilsX.weekdayName(d)] ??
                      DateUtilsX.weekdayName(d);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onSelect(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 64, minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? AppColors.tealPale : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: active
                              ? AppColors.teal
                              : Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? const Color(0xFF356E6A)
                                    : AppColors.ink)),
                        Text('[${DateUtilsX.shortDate(d)}]',
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: active
                                    ? const Color(0xFF356E6A)
                                    : AppColors.inkLight)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
