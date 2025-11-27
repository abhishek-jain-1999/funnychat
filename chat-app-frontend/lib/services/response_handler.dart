import 'package:chat_app_frontend/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'log_service.dart';
import 'snackbar_service.dart';

class ResponseHandler {
  static Future<void> handleApiCall(
    BuildContext context,
    Future<void> Function() apiCall, {
    String? successMessage,
    Function()? onSuccess,
    Function(dynamic error, BuildContext context)? onError,
  }) async {
    try {
      await apiCall();
      if (successMessage != null) {
        SnackbarService.showSuccess(successMessage);
      }
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      if (onError != null) {
        onError(e, context);
        return;
      }
      handleError(e, context);
    }
  }

  static void handleError(dynamic error, BuildContext context) {
    LogService.error('Handling error', error);

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          SnackbarService.showError('Session expired. Please login again.');
          ApiService.clearToken();
          // Navigate to login screen
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
          break;
        case 403:
          SnackbarService.showError('Access denied: ${error.message}');
          break;
        case 404:
          SnackbarService.showError(error.message);
          break;
        case 500:
          SnackbarService.showError('Server error. Please try again later.');
          break;
        default:
          SnackbarService.showError(error.message);
      }
    } else {
      SnackbarService.showError('An unexpected error occurred: $error');
    }
  }
}
