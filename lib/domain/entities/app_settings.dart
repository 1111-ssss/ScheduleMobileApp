import 'package:flutter/foundation.dart';

/// Всё, что приложение запоминает между запусками.
/// Один объект — один JSON; режимы страниц хранятся независимо.
@immutable
final class StoredState {
  final bool isGroupMode;
  final String? specialty;
  final String? group;
  final String teacher;
  final bool scheduleWeekMode;
  final bool favoritesWeekMode;
  final int tab;

  const StoredState({
    this.isGroupMode = true,
    this.specialty,
    this.group,
    this.teacher = '',
    this.scheduleWeekMode = true,
    this.favoritesWeekMode = false,
    this.tab = 0,
  });

  Map<String, dynamic> toJson() => {
        'isGroupMode': isGroupMode,
        'specialty': specialty,
        'group': group,
        'teacher': teacher,
        'scheduleWeekMode': scheduleWeekMode,
        'favoritesWeekMode': favoritesWeekMode,
        'tab': tab,
      };

  factory StoredState.fromJson(Map<String, dynamic> j) => StoredState(
        isGroupMode: (j['isGroupMode'] as bool?) ?? true,
        specialty: j['specialty'] as String?,
        group: j['group'] as String?,
        teacher: (j['teacher'] as String?) ?? '',
        scheduleWeekMode: (j['scheduleWeekMode'] as bool?) ?? true,
        favoritesWeekMode: (j['favoritesWeekMode'] as bool?) ?? false,
        tab: (j['tab'] as num?)?.toInt() ?? 0,
      );
}
