import 'package:flutter/foundation.dart';

enum FavoriteKind { group, teacher }

/// Избранная цель: либо группа, либо преподаватель.
@immutable
final class Favorite {
  final String id;
  final FavoriteKind kind;
  final String? specialty;
  final String? group;
  final String? teacher;

  const Favorite({
    required this.id,
    required this.kind,
    this.specialty,
    this.group,
    this.teacher,
  });

  String get label {
    switch (kind) {
      case FavoriteKind.group:
        return 'Группа ${group ?? ''}'.trim();
      case FavoriteKind.teacher:
        return teacher ?? '';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'specialty': specialty,
        'group': group,
        'teacher': teacher,
      };

  factory Favorite.fromJson(Map<String, dynamic> j) => Favorite(
        id: j['id'] as String,
        kind: FavoriteKind.values.byName(j['kind'] as String),
        specialty: j['specialty'] as String?,
        group: j['group'] as String?,
        teacher: j['teacher'] as String?,
      );
}
