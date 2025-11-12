import 'package:flutter/foundation.dart';
import 'package:mono_connect_sdk/src/core/log/mono_logger.dart';

/// Default logger implementation using print statements
class DefaultMonoLogger implements MonoLogger {
  @override
  void info(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print(
        '🔵 [MONO CONNECT INFO] $message${data != null ? ' | Data: $data' : ''}',
      );
    }
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print(
        '🔴 [MONO CONNECT ERROR] $message${error != null ? ' | Error: $error' : ''}',
      );
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  @override
  void debug(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print(
        '⚪ [MONO CONNECT DEBUG] $message${data != null ? ' | Data: $data' : ''}',
      );
    }
  }
}
