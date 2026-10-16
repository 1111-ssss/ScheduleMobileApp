import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/prefs_store.dart';

/// Реализация [PrefsStore] на SharedPreferences.
/// Ключи гранулярные — каждый экран пишет только своё (см. интерфейс).
final class SharedPrefsStore implements PrefsStore {
  static const _kMode = 'app.isGroupMode';
  static const _kSpecialty = 'app.specialty';
  static const _kGroup = 'app.group';
  static const _kTeacher = 'app.teacher';
  static const _kScheduleWeek = 'app.scheduleWeekMode';
  static const _kFavoritesWeek = 'app.favoritesWeekMode';
  static const _kTab = 'app.tab';

  final SharedPreferences _prefs;
  const SharedPrefsStore(this._prefs);

  @override
  Future<StoredState> load() async => StoredState(
        isGroupMode: _prefs.getBool(_kMode) ?? true,
        specialty: _prefs.getString(_kSpecialty),
        group: _prefs.getString(_kGroup),
        teacher: _prefs.getString(_kTeacher) ?? '',
        scheduleWeekMode: _prefs.getBool(_kScheduleWeek) ?? true,
        favoritesWeekMode: _prefs.getBool(_kFavoritesWeek) ?? false,
        tab: _prefs.getInt(_kTab) ?? 0,
      );

  @override
  Future<void> saveMode({required bool isGroupMode}) =>
      _prefs.setBool(_kMode, isGroupMode);

  @override
  Future<void> saveScheduleSelection({
    String? specialty,
    String? group,
    String? teacher,
  }) async {
    if (specialty != null) await _prefs.setString(_kSpecialty, specialty);
    if (group != null) await _prefs.setString(_kGroup, group);
    if (teacher != null) await _prefs.setString(_kTeacher, teacher);
  }

  @override
  Future<void> saveScheduleWeekMode(bool weekMode) =>
      _prefs.setBool(_kScheduleWeek, weekMode);

  @override
  Future<void> saveFavoritesWeekMode(bool weekMode) =>
      _prefs.setBool(_kFavoritesWeek, weekMode);

  @override
  Future<void> saveTab(int tab) => _prefs.setInt(_kTab, tab);
}

/// Избранное на SharedPreferences — та же persist-логика вместо in-memory,
/// интерфейс [FavoritesRepository] не меняется (OCP).
final class SharedPrefsFavoritesRepository implements FavoritesRepository {
  static const _kFavorites = 'app.favorites';
  final SharedPreferences _prefs;
  const SharedPrefsFavoritesRepository(this._prefs);

  @override
  Future<List<Favorite>> load() async {
    final raw = _prefs.getString(_kFavorites);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Favorite.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<Favorite> items) => _prefs.setString(
      _kFavorites, jsonEncode(items.map((e) => e.toJson()).toList()));

  @override
  Future<void> add(Favorite favorite) async {
    final items = (await load()).toList()
      ..removeWhere((e) => e.id == favorite.id)
      ..add(favorite);
    await _persist(items);
  }

  @override
  Future<void> remove(String id) async {
    final items = (await load()).toList()
      ..removeWhere((e) => e.id == id);
    await _persist(items);
  }
}
