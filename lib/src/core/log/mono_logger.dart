/// Logger interface for Mono Connect
abstract class MonoLogger {
  void info(String message, [Map<String, dynamic>? data]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
  void debug(String message, [Map<String, dynamic>? data]);
}
