import 'package:chat_app_frontend/services/snackbar_service.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static void info(String message) {
    if (kDebugMode) {
      print('INFO: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      print('WARN: $message');
    }
  }

  static void releaseSnackBar(String message,) {
    SnackbarService.showError('Snackbar . $message.');
  }
}
