import '../../core/error/failure.dart';
import '../../domain/entities/day_schedule.dart';
import '../../domain/repositories/directory_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/entities/favorite.dart';
import '../datasources/schedule_api.dart';

/// DRY: общая обёртка ошибок транспортного уровня.
Future<T> _guard<T>(Future<T> Function() f, String what) async {
  try {
    return await f();
  } on Failure {
    rethrow;
  } catch (e) {
    throw Failure('Не удалось загрузить: $what ($e)');
  }
}

final class DirectoryRepositoryImpl implements DirectoryRepository {
  final ScheduleApi _api;
  const DirectoryRepositoryImpl(this._api);

  @override
  Future<Map<String, List<String>>> groups() =>
      _guard(() => _api.getGroups(), 'группы');

  @override
  Future<List<String>> teachers() =>
      _guard(() => _api.getTeachers(), 'преподаватели');
}

final class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleApi _api;
  const ScheduleRepositoryImpl(this._api);

  @override
  Future<List<DaySchedule>> groupWeek({
    required String group,
    required DateTime from,
    required int days,
  }) =>
      _guard(() async {
        final dto =
            await _api.getGroupWeek(group: group, from: from, days: days);
        return dto.map((e) => e.toEntity()).toList();
      }, 'расписание группы');

  @override
  Future<DaySchedule?> groupDay({
    required String group,
    required DateTime date,
  }) =>
      _guard(() async {
        final dto = await _api.getGroupDay(group: group, date: date);
        return dto?.toEntity();
      }, 'расписание группы на день');

  @override
  Future<List<DaySchedule>> teacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  }) =>
      _guard(() async {
        final dto =
            await _api.getTeacherWeek(teacher: teacher, from: from, days: days);
        return dto.map((e) => e.toEntity()).toList();
      }, 'расписание преподавателя');

  @override
  Future<DaySchedule?> teacherDay({
    required String teacher,
    required DateTime date,
  }) =>
      _guard(() async {
        final dto = await _api.getTeacherDay(teacher: teacher, date: date);
        return dto?.toEntity();
      }, 'расписание преподавателя на день');

  @override
  Future<List<DaySchedule>> fullDay({required DateTime date}) => _guard(() async {
        final dto = await _api.getFullSchedule(date: date);
        return dto.map((e) => e.toEntity()).toList();
      }, 'общее расписание');
}

/// In-memory избранное. Замена на SharedPreferences позже:
/// создать SharedPrefsFavoritesRepository с тем же интерфейсом.
final class InMemoryFavoritesRepository implements FavoritesRepository {
  final List<Favorite> _items = [];
  @override
  Future<List<Favorite>> load() async => List.unmodifiable(_items);

  @override
  Future<void> add(Favorite favorite) async {
    _items.removeWhere((e) => e.id == favorite.id);
    _items.add(favorite);
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
