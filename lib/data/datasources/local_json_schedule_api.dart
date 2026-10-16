import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/date_utils.dart';
import '../models/day_schedule_dto.dart';
import 'schedule_api.dart';

/// Временная реализация [ScheduleApi] на seed-JSON из assets.
/// Читает файлы один раз и кэширует в памяти. Фильтрация
/// по группе/преподавателю/дате — здесь, чтобы HTTP-реализация
/// позже просто проксировала query-параметры на сервер.
///
/// Файлы:
///   assets/seed/teachers.json, groups.json,
///   group_schedules.json, teacher_schedules.json, full_schedules.json
final class LocalJsonScheduleApi implements ScheduleApi {
  final AssetBundle _bundle;
  Map<String, List<DayScheduleDto>>? _groupCache;
  Map<String, List<DayScheduleDto>>? _teacherCache;
  Map<String, List<DayScheduleDto>>? _fullCache;
  List<String>? _teachersCache;
  Map<String, List<String>>? _groupsCache;

  LocalJsonScheduleApi({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  Future<Map<String, List<DayScheduleDto>>> _groupsSchedules() async {
    if (_groupCache != null) return _groupCache!;
    final raw = await _bundle.loadString('assets/seed/group_schedules.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _groupCache = json.map((k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
            .toList()));
    return _groupCache!;
  }

  Future<Map<String, List<DayScheduleDto>>> _teacherSchedules() async {
    if (_teacherCache != null) return _teacherCache!;
    final raw = await _bundle.loadString('assets/seed/teacher_schedules.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _teacherCache = json.map((k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
            .toList()));
    return _teacherCache!;
  }

  Future<Map<String, List<DayScheduleDto>>> _fullSchedules() async {
    if (_fullCache != null) return _fullCache!;
    final raw = await _bundle.loadString('assets/seed/full_schedules.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _fullCache = json.map((k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
            .toList()));
    return _fullCache!;
  }

  List<DayScheduleDto> _slice(List<DayScheduleDto> all, DateTime from, int d) {
    final to = from.add(Duration(days: d));
    final out = all.where((e) {
      final dt = DateUtilsX.parseApiDate(e.date);
      return !dt.isBefore(DateTime(from.year, from.month, from.day)) &&
          dt.isBefore(DateTime(to.year, to.month, to.day));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  @override
  Future<Map<String, List<String>>> getGroups() async {
    if (_groupsCache != null) return _groupsCache!;
    final raw = await _bundle.loadString('assets/seed/groups.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _groupsCache = json.map(
        (k, v) => MapEntry(k, (v as List).map((e) => e as String).toList()));
    return _groupsCache!;
  }

  @override
  Future<List<String>> getTeachers() async {
    if (_teachersCache != null) return _teachersCache!;
    final raw = await _bundle.loadString('assets/seed/teachers.json');
    _teachersCache = (jsonDecode(raw) as List).map((e) => e as String).toList();
    return _teachersCache!;
  }

  @override
  Future<List<DayScheduleDto>> getGroupWeek({
    required String group,
    required DateTime from,
    required int days,
  }) async {
    final all = (await _groupsSchedules())[group] ?? const [];
    return _slice(all, from, days);
  }

  @override
  Future<DayScheduleDto?> getGroupDay({
    required String group,
    required DateTime date,
  }) async {
    final key = DateUtilsX.apiDate(date);
    final all = (await _groupsSchedules())[group] ?? const [];
    return all.where((e) => e.date == key).firstOrNull;
  }

  @override
  Future<List<DayScheduleDto>> getTeacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  }) async {
    final all = (await _teacherSchedules())[teacher] ?? const [];
    return _slice(all, from, days);
  }

  @override
  Future<DayScheduleDto?> getTeacherDay({
    required String teacher,
    required DateTime date,
  }) async {
    final key = DateUtilsX.apiDate(date);
    final all = (await _teacherSchedules())[teacher] ?? const [];
    return all.where((e) => e.date == key).firstOrNull;
  }

  @override
  Future<List<DayScheduleDto>> getFullSchedule({required DateTime date}) async {
    return (await _fullSchedules())[DateUtilsX.apiDate(date)] ?? const [];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
