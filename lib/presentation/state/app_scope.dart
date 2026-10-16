import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_json_schedule_api.dart';
import '../../data/datasources/schedule_api.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../data/repositories/shared_prefs_store.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/prefs_store.dart';
import '../../domain/usecases/usecases.dart';
import 'favorites_controller.dart';
import 'schedule_controller.dart';

/// Composition root: здесь решается, какая реализация [ScheduleApi]
/// подставляется под интерфейсы. Переход на реальный бэкенд —
/// одна строка (замена LocalJsonScheduleApi на HttpScheduleApi).
///
/// Создаётся асинхронно ([AppDependencies.create]), т.к. читает
/// сохранённое состояние из SharedPreferences до построения UI.
final class AppDependencies {
  final ScheduleApi api;
  final PrefsStore prefs;
  final StoredState initial;
  late final GetGroups getGroups;
  late final GetTeachers getTeachers;
  late final GetGroupWeek getGroupWeek;
  late final GetTeacherWeek getTeacherWeek;
  late final GetFullDay getFullDay;
  late final LoadFavorites loadFavorites;
  late final AddFavorite addFavorite;
  late final RemoveFavorite removeFavorite;

  AppDependencies._({
    required this.api,
    required this.prefs,
    required this.initial,
    required FavoritesRepository favoritesRepo,
  }) {
    final dir = DirectoryRepositoryImpl(api);
    final sch = ScheduleRepositoryImpl(api);
    getGroups = GetGroups(dir);
    getTeachers = GetTeachers(dir);
    getGroupWeek = GetGroupWeek(sch);
    getTeacherWeek = GetTeacherWeek(sch);
    getFullDay = GetFullDay(sch);
    loadFavorites = LoadFavorites(favoritesRepo);
    addFavorite = AddFavorite(favoritesRepo);
    removeFavorite = RemoveFavorite(favoritesRepo);
  }

  static Future<AppDependencies> create({ScheduleApi? api}) async {
    final sp = await SharedPreferences.getInstance();
    final prefs = SharedPrefsStore(sp);
    final initial = await prefs.load();
    return AppDependencies._(
      api: api ?? LocalJsonScheduleApi(),
      prefs: prefs,
      initial: initial,
      favoritesRepo: SharedPrefsFavoritesRepository(sp),
    );
  }

  ScheduleController scheduleController() => ScheduleController(
        getGroups,
        getTeachers,
        getGroupWeek,
        getTeacherWeek,
        getFullDay,
        prefs: prefs,
        initial: initial,
      );

  FavoritesController favoritesController() => FavoritesController(
        loadFavorites,
        addFavorite,
        removeFavorite,
        getGroupWeek,
        getTeacherWeek,
        prefs: prefs,
        initialWeekMode: initial.favoritesWeekMode,
      );
}

final class AppScope extends InheritedWidget {
  final AppDependencies deps;
  const AppScope({super.key, required this.deps, required super.child});

  static AppDependencies of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.deps;

  @override
  bool updateShouldNotify(AppScope old) => false;
}
