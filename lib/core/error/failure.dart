/// Доменный сбой. Один тип на все слои (KISS):
/// data маппит исключения в Failure, presentation показывает message.
final class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure($message)';
}
