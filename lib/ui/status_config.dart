import 'package:flutter/material.dart';

class StatusConfig {
  static Color colorFor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData iconFor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'diproses':
        return Icons.engineering;
      case 'selesai':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  static String labelFor(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }
}
