import 'dart:convert';
import 'dart:io';

import '../../core/utils/date_utils.dart';
import '../models/day_schedule_dto.dart';
import 'schedule_api.dart';

/// Готовая HTTP-реализация [ScheduleApi] под бэкенд из ТЗ.
/// НЕ используется по умолчанию (используется LocalJsonScheduleApi),
/// подключается одной строкой в composition root, когда API будет готово:
/// ```dart
/// ScheduleApi api = HttpScheduleApi(baseUrl: 'https://example.com');
/// ```
/// Использует dart:io HttpClient — внешних пакетов не нужно.
///
/// ВНИМАНИЕ: имена query-параметров (teacher/group/from/days/date) —
/// допущение, т.к. в ТЗ даны только пути. При расхождении с реальным
/// API правится только [_get] вызовы этого файла.
final class HttpScheduleApi implements ScheduleApi {
  final String baseUrl;
  final HttpClient _client;

  HttpScheduleApi({required this.baseUrl, HttpClient? client})
      : _client = client ?? HttpClient();

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final req = await _client.getUrl(uri);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode == 429) {
      throw const HttpException('Слишком много запросов, попробуйте позже');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Сервер вернул ${resp.statusCode}: $body');
    }
    return jsonDecode(body);
  }

  @override
  Future<List<String>> getTeachers() async {
    final data = await _get('/api/data/teachers') as List;
    return data.map((e) => e as String).toList();
  }

  @override
  Future<Map<String, List<String>>> getGroups() async {
    final data = await _get('/api/data/groups') as Map<String, dynamic>;
    return data.map(
        (k, v) => MapEntry(k, (v as List).map((e) => e as String).toList()));
  }

  @override
  Future<List<DayScheduleDto>> getGroupWeek({
    required String group,
    required DateTime from,
    required int days,
  }) async {
    final data = await _get('Schedule/group/week', {
      'group': group,
      'from': DateUtilsX.apiDate(from),
      'days': '$days',
    }) as List;
    return data
        .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DayScheduleDto?> getGroupDay({
    required String group,
    required DateTime date,
  }) async {
    final data = await _get('Schedule/group/day', {
      'group': group,
      'date': DateUtilsX.apiDate(date),
    }) as Map<String, dynamic>;
    return DayScheduleDto.fromJson(data);
  }

  @override
  Future<List<DayScheduleDto>> getTeacherWeek({
    required String teacher,
    required DateTime from,
    required int days,
  }) async {
    final data = await _get('Schedule/teacher/week', {
      'teacher': teacher,
      'from': DateUtilsX.apiDate(from),
      'days': '$days',
    }) as List;
    return data
        .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DayScheduleDto?> getTeacherDay({
    required String teacher,
    required DateTime date,
  }) async {
    final data = await _get('Schedule/teacher/day', {
      'teacher': teacher,
      'date': DateUtilsX.apiDate(date),
    }) as Map<String, dynamic>;
    return DayScheduleDto.fromJson(data);
  }

  @override
  Future<List<DayScheduleDto>> getFullSchedule({required DateTime date}) async {
    final data = await _get('Schedule', {
      'date': DateUtilsX.apiDate(date),
    }) as List;
    return data
        .map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
