import 'package:flutter/material.dart';

({Color color, IconData icon, String text}) statusInfo(String status) {
  switch (status.toLowerCase()) {
    case 'selesai':
      return (color: Colors.green, icon: Icons.check_circle, text: 'Selesai');
    case 'diproses':
      return (color: Colors.orange, icon: Icons.hourglass_bottom, text: 'Diproses');
    case 'ditolak':
      return (color: Colors.red, icon: Icons.cancel, text: 'Ditolak');
    default:
      return (color: Colors.grey, icon: Icons.pending, text: 'Pending');
  }
}

Color statusColor(String status) => statusInfo(status).color;