import '../entities/favorite.dart';

/// Избранное. Сейчас in-memory, позже — SharedPreferences без смены интерфейса.
abstract interface class FavoritesRepository {
  Future<List<Favorite>> load();
  Future<void> add(Favorite favorite);
  Future<void> remove(String id);
}
