import 'package:flutter/material.dart';
import '../theme.dart';

enum ActivityType {
  inbound, // Receiving goods
  delivery, // Sending goods
  rental,   // Booking space
  invoice,  // Payment
}

class DashboardActivity {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final ActivityType type;
  final double? amount; // Optional for value display

  DashboardActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    this.amount,
  });

  // Helpers for UI
  IconData get icon {
    switch (type) {
      case ActivityType.inbound:
        return Icons.move_to_inbox_rounded;
      case ActivityType.delivery:
        return Icons.local_shipping_outlined;
      case ActivityType.rental:
        return Icons.warehouse_rounded;
      case ActivityType.invoice:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.inbound:
        return Colors.green;
      case ActivityType.delivery:
        return Colors.blue;
      case ActivityType.rental:
        return AppColors.bluePrimary;
      case ActivityType.invoice:
        return Colors.teal;
    }
  }


  // Serialization for Local Persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
      'type': type.index, // Store enum index
      'amount': amount,
    };
  }

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      date: DateTime.parse(json['date']),
      type: ActivityType.values[json['type'] as int],
      amount: json['amount'],
    );
  }
}
