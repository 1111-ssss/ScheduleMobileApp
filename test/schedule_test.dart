import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_app/data/datasources/schedule_api.dart';
import 'package:schedule_app/data/models/day_schedule_dto.dart';
import 'package:schedule_app/data/repositories/repositories_impl.dart';

/// Минимальный фейк транспортного уровня: проверяет, что репозиторий
/// зависит только от интерфейса ScheduleApi (DIP), а DTO маппится в сущность.
final class FakeApi implements ScheduleApi {
  @override
  Future<Map<String, List<String>>> getGroups() async =>
      {'РиСТПОиС': ['Б21']};

  @override
  Future<List<String>> getTeachers() async => ['Иванова И.И.'];

  @override
  Future<List<DayScheduleDto>> getGroupWeek({
    required String group,
    required DateTime from,
    required int days,
  }) async => [
        DayScheduleDto.fromJson({
          'date': '2025-11-03',
          'weekday': 'Понедельник',
          'group': group,
          'lessons': [
            {
              'order': 1,
              'startTime': '8:00',
              'endTime': '9:35',
              'subject': 'Экономика',
              'teacher': 'Иванова И.И.',
              'classroom': 'Каб. 409',
            },
          ],
        }),
      ];

  @override
  Future<DayScheduleDto?> getGroupDay(
          {required String group, required DateTime date}) async =>
      null;

  @override
  Future<List<DayScheduleDto>> getTeacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  }) async =>
      [];

  @override
  Future<DayScheduleDto?> getTeacherDay(
          {required String teacher, required DateTime date}) async =>
      null;

  @override
  Future<List<DayScheduleDto>> getFullSchedule(
          {required DateTime date}) async =>
      [];
}

void main() {
  test('ScheduleRepositoryImpl маппит DTO недели группы в сущности', () async {
    final repo = ScheduleRepositoryImpl(FakeApi());
    final week = await repo.groupWeek(
        group: 'Б21', from: DateTime(2025, 11, 3), days: 6);

    expect(week, hasLength(1));
    expect(week.first.group, 'Б21');
    expect(week.first.lessonsCount, 1);
    expect(week.first.lessons.first.subject, 'Экономика');
    expect(week.first.title(isGroupMode: true), 'Группа Б21 [03.11]');
  });

  test('DirectoryRepositoryImpl отдаёт справочники', () async {
    final repo = DirectoryRepositoryImpl(FakeApi());
    expect(await repo.teachers(), ['Иванова И.И.']);
    expect(await repo.groups(), {'РиСТПОиС': ['Б21']});
  });
}
