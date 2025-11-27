import 'package:flutter/material.dart';
import '../config/global_keys.dart';

class SnackbarService {
  static void showSuccess(String message) {
    _show(message, Colors.green, Icons.check_circle);
  }

  static void showError(String message) {
    _show(message, Colors.red, Icons.error);
  }

  static void showInfo(String message) {
    _show(message, Colors.blue, Icons.info);
  }

  static void _show(String message, Color color, IconData icon) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
