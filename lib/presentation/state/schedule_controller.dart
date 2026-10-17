import 'dart:async';

import 'package:flutter/foundation.dart';

// ignore_for_file: prefer_initializing_formals — конструкторы намеренно
// принимают публичные параметры под приватные поля (стабильный API).

import '../../core/utils/date_utils.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/day_schedule.dart';
import '../../domain/repositories/prefs_store.dart';
import '../../domain/usecases/usecases.dart';

enum ScheduleMode { group, teacher }

/// Состояние экрана просмотра. Один ChangeNotifier на экран (KISS):
/// держит фильтры + загруженные дни недели. Ничего не знает про JSON/HTTP —
/// только use case-ы (DIP).
final class ScheduleController extends ChangeNotifier {
  final GetGroups _getGroups;
  final GetTeachers _getTeachers;
  final GetGroupWeek _getGroupWeek;
  final GetTeacherWeek _getTeacherWeek;
  final GetFullDay _getFullDay;
  final PrefsStore? _prefs;
  final StoredState? _initial;

  ScheduleController(
    this._getGroups,
    this._getTeachers,
    this._getGroupWeek,
    this._getTeacherWeek,
    this._getFullDay, {
    PrefsStore? prefs,
    StoredState? initial,
  })  : _prefs = prefs,
        _initial = initial;

  ScheduleMode mode = ScheduleMode.group;
  bool weekMode = true;

  Map<String, List<String>> specialties = const {};
  List<String> teachers = const [];
  String? selectedSpecialty;
  String? selectedGroup;
  String selectedTeacher = '';
  String teacherQuery = '';

  /// Seed покрывает неделю с 05.10.2026 (и отдельные дни 18.09.2026,
  /// 02.10.2026) — стартуем с неё, чтобы демо открывалось с данными.
  /// Навигация стрелками ходит по любым неделям.
  DateTime weekStart = DateTime(2026, 10, 5);
  int selectedDayIndex = 0;

  List<DaySchedule> week = const [];
  bool loadingDirectory = true;
  bool loadingWeek = false;
  String? error;

  List<String> get groupsOfSelected =>
      selectedSpecialty == null ? const [] : (specialties[selectedSpecialty] ?? const []);

  List<String> get filteredTeachers {
    final q = teacherQuery.trim().toLowerCase();
    if (q.isEmpty) return teachers;
    return teachers.where((t) => t.toLowerCase().contains(q)).toList();
  }

  DateTime get selectedDate => weekStart.add(Duration(days: selectedDayIndex));

  Future<void> init() async {
    loadingDirectory = true;
    notifyListeners();
    try {
      final results = await Future.wait([_getGroups(), _getTeachers()]);
      specialties = results[0] as Map<String, List<String>>;
      teachers = results[1] as List<String>;
      _applyInitial();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loadingDirectory = false;
    notifyListeners();
    await reloadWeek();
  }

  /// Восстанавливает последнее состояние с прошлого запуска.
  /// Сохранённые значения проверяются по свежим справочникам —
  /// если группа/преподаватель пропали из API, берём первые доступные.
  void _applyInitial() {
    final s = _initial;
    if (s == null) {
      selectedSpecialty = specialties.keys.firstOrNull;
      selectedGroup = groupsOfSelected.firstOrNull;
      selectedTeacher = teachers.firstOrNull ?? '';
      return;
    }
    mode = s.isGroupMode ? ScheduleMode.group : ScheduleMode.teacher;
    weekMode = s.scheduleWeekMode;
    if (specialties.containsKey(s.specialty)) {
      selectedSpecialty = s.specialty;
    } else {
      selectedSpecialty = specialties.keys.firstOrNull;
    }
    final groups = groupsOfSelected;
    selectedGroup =
        (s.group != null && groups.contains(s.group)) ? s.group : groups.firstOrNull;
    selectedTeacher =
        teachers.contains(s.teacher) ? s.teacher : (teachers.firstOrNull ?? '');
    if (!weekMode) selectedDayIndex = _todayIndex();
  }

  void _persistSelection() {
    final p = _prefs;
    if (p == null) return;
    unawaited(p.saveMode(isGroupMode: mode == ScheduleMode.group));
    unawaited(p.saveScheduleSelection(
      specialty: selectedSpecialty,
      group: selectedGroup,
      teacher: selectedTeacher,
    ));
  }

  Future<void> reloadWeek() async {
    if (mode == ScheduleMode.group && selectedGroup == null) return;
    if (mode == ScheduleMode.teacher && selectedTeacher.isEmpty) return;
    loadingWeek = true;
    error = null;
    notifyListeners();
    try {
      week = mode == ScheduleMode.group
          ? await _getGroupWeek(group: selectedGroup!, from: weekStart)
          : await _getTeacherWeek(teacher: selectedTeacher, from: weekStart);
      if (selectedDayIndex >= week.length) selectedDayIndex = 0;
    } catch (e) {
      week = const [];
      error = e.toString();
    }
    loadingWeek = false;
    notifyListeners();
  }

  void setMode(ScheduleMode m) {
    mode = m;
    notifyListeners();
    _persistSelection();
    reloadWeek();
  }

  void setWeekMode(bool v) {
    weekMode = v;
    // При первом открытии вкладки "День" показываем день недели,
    // соответствующий сегодняшнему (в пределах загруженной недели).
    if (!v) selectedDayIndex = _todayIndex();
    notifyListeners();
    final p = _prefs;
    if (p != null) unawaited(p.saveScheduleWeekMode(v));
  }

  /// Индекс сегодняшнего дня недели в загруженной неделе.
  /// Если недели нет — 0; воскресенье на 6-дневке -> последний день.
  int _todayIndex() {
    if (week.isEmpty) return 0;
    final idx = DateTime.now().weekday - 1;
    return idx.clamp(0, week.length - 1);
  }

  void selectSpecialty(String? s) {
    selectedSpecialty = s;
    selectedGroup = groupsOfSelected.firstOrNull;
    notifyListeners();
    _persistSelection();
    reloadWeek();
  }

  void selectGroup(String? g) {
    selectedGroup = g;
    notifyListeners();
    _persistSelection();
    reloadWeek();
  }

  void selectTeacher(String t) {
    selectedTeacher = t;
    teacherQuery = '';
    notifyListeners();
    _persistSelection();
    reloadWeek();
  }

  void setTeacherQuery(String q) {
    teacherQuery = q;
    notifyListeners();
  }

  void shiftWeek(int days) {
    weekStart = weekStart.add(Duration(days: days));
    selectedDayIndex = 0;
    notifyListeners();
    reloadWeek();
  }

  Future<void> pickDate(DateTime d) async {
    weekStart = DateUtilsX.weekStart(d);
    notifyListeners();
    await reloadWeek();
    final idx = week.indexWhere((e) =>
        e.date.year == d.year && e.date.month == d.month && e.date.day == d.day);
    selectedDayIndex = idx >= 0 ? idx : _todayIndex();
    notifyListeners();
  }

  void selectDay(int i) {
    selectedDayIndex = i;
    notifyListeners();
  }

  Future<List<DaySchedule>> fullDay(DateTime date) =>
      _getFullDay(date: date);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
