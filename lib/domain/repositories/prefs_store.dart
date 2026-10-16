import '../entities/app_settings.dart';

/// Гранулярное хранилище настроек (ISP): каждый экран пишет только свои ключи,
/// поэтому контроллеры не затирают чужие значения. Реализация —
/// SharedPreferences, но интерфейс позволяет подменить (DIP).
abstract interface class PrefsStore {
  /// Полный снимок для стартовой инициализации. Возвращает дефолты,
  /// если приложение запущено впервые.
  Future<StoredState> load();

  Future<void> saveMode({required bool isGroupMode});
  Future<void> saveScheduleSelection({
    String? specialty,
    String? group,
    String? teacher,
  });
  Future<void> saveScheduleWeekMode(bool weekMode);
  Future<void> saveFavoritesWeekMode(bool weekMode);
  Future<void> saveTab(int tab);
}
