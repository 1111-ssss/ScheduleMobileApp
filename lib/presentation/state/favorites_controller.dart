import 'dart:async';

import 'package:flutter/foundation.dart';

// ignore_for_file: prefer_initializing_formals — см. schedule_controller.dart.

import '../../core/utils/date_utils.dart';
import '../../domain/entities/day_schedule.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/repositories/prefs_store.dart';
import '../../domain/usecases/usecases.dart';

/// Состояние экрана избранного. Хранит цели + загруженные недели по ним.
/// Ключ кэша — id избранного. Режим Неделя/День — свой, независимый
/// от страницы расписания, и тоже сохраняется между запусками.
final class FavoritesController extends ChangeNotifier {
  final LoadFavorites _load;
  final AddFavorite _add;
  final RemoveFavorite _remove;
  final GetGroupWeek _getGroupWeek;
  final GetTeacherWeek _getTeacherWeek;
  final PrefsStore? _prefs;

  FavoritesController(
    this._load,
    this._add,
    this._remove,
    this._getGroupWeek,
    this._getTeacherWeek, {
    PrefsStore? prefs,
    bool initialWeekMode = false,
  })  : _prefs = prefs,
        weekMode = initialWeekMode;

  List<Favorite> items = const [];
  Map<String, List<DaySchedule>> weeks = const {};
  DateTime weekStart = DateTime(2026, 10, 5);
  bool loading = false;
  String? error;
  bool weekMode;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    try {
      items = await _load();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
    await reloadAll();
  }

  Future<void> reloadAll() async {
    final map = <String, List<DaySchedule>>{};
    for (final f in items) {
      try {
        map[f.id] = f.kind == FavoriteKind.group
            ? await _getGroupWeek(group: f.group ?? '', from: weekStart)
            : await _getTeacherWeek(teacher: f.teacher ?? '', from: weekStart);
      } catch (_) {
        map[f.id] = const [];
      }
    }
    weeks = map;
    notifyListeners();
  }

  Future<void> add(Favorite f) async {
    await _add(f);
    items = await _load();
    notifyListeners();
    await reloadAll();
  }

  Future<void> remove(String id) async {
    await _remove(id);
    items = await _load();
    notifyListeners();
  }

  void setWeekMode(bool v) {
    weekMode = v;
    notifyListeners();
    final p = _prefs;
    if (p != null) unawaited(p.saveFavoritesWeekMode(v));
  }

  void shiftWeek(int days) {
    weekStart = weekStart.add(Duration(days: days));
    reloadAll();
  }

  void pickDate(DateTime d) {
    weekStart = DateUtilsX.weekStart(d);
    reloadAll();
  }
}
