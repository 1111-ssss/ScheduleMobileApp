/// Справочники: преподаватели и специальности->группы.
/// ISP: отдельный узкий интерфейс, не смешан с расписанием.
abstract interface class DirectoryRepository {
  Future<List<String>> teachers();
  Future<Map<String, List<String>>> groups();
}
