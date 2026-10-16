import '../entities/day_schedule.dart';
import '../repositories/directory_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/schedule_repository.dart';
import '../entities/favorite.dart';

/// Тонкие use case-ы: SRP — один класс = одна задача,
/// вся логика источников данных остаётся в data-слое.
/// KISS: без параметров-обёрток, только нужные аргументы.

final class GetGroups {
  final DirectoryRepository _repo;
  const GetGroups(this._repo);
  Future<Map<String, List<String>>> call() => _repo.groups();
}

final class GetTeachers {
  final DirectoryRepository _repo;
  const GetTeachers(this._repo);
  Future<List<String>> call() => _repo.teachers();
}

final class GetGroupWeek {
  final ScheduleRepository _repo;
  const GetGroupWeek(this._repo);
  Future<List<DaySchedule>> call({
    required String group,
    required DateTime from,
    int days = 6,
  }) =>
      _repo.groupWeek(group: group, from: from, days: days);
}

final class GetTeacherWeek {
  final ScheduleRepository _repo;
  const GetTeacherWeek(this._repo);
  Future<List<DaySchedule>> call({
    required String teacher,
    required DateTime from,
    int days = 6,
  }) =>
      _repo.teacherWeek(teacher: teacher, from: from, days: days);
}

final class GetFullDay {
  final ScheduleRepository _repo;
  const GetFullDay(this._repo);
  Future<List<DaySchedule>> call({required DateTime date}) =>
      _repo.fullDay(date: date);
}

final class LoadFavorites {
  final FavoritesRepository _repo;
  const LoadFavorites(this._repo);
  Future<List<Favorite>> call() => _repo.load();
}

final class AddFavorite {
  final FavoritesRepository _repo;
  const AddFavorite(this._repo);
  Future<void> call(Favorite f) => _repo.add(f);
}

final class RemoveFavorite {
  final FavoritesRepository _repo;
  const RemoveFavorite(this._repo);
  Future<void> call(String id) => _repo.remove(id);
}
