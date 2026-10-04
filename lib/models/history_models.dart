import 'package:flutter/material.dart';
import '../theme.dart';

enum ActivityType {
  inbound, // Receiving goods
  delivery, // Sending goods
  rental,   // Booking space
  invoice,  // Payment
  inventory, // Damaged goods / quarantine
}

class DashboardActivity {
  final String id;
  final String title;
  final String? titleAr;
  final String subtitle;
  final String? subtitleAr;
  final DateTime date;
  final ActivityType type;
  final double? amount; // Optional for value display

  DashboardActivity({
    required this.id,
    required this.title,
    this.titleAr,
    required this.subtitle,
    this.subtitleAr,
    required this.date,
    required this.type,
    this.amount,
  });

  String getDisplayTitle(bool isAr) {
    if (isAr) {
      if (titleAr != null && titleAr!.trim().isNotEmpty) return titleAr!;
      if (title.contains('Payment Success')) return 'تم سداد الفاتورة بنجاح';
      if (title.contains('Invoice Generated')) return 'تم إنشاء الفاتورة';
      if (title.contains('Inbound Shipment') || title.contains('Inbound STO Intake')) return 'شحنة واردة للمستودع (STO)';
      if (title.contains('Delivery Dispatch WAY') || title.contains('Delivery Order')) return 'طلب شحن وتوصيل مشتري';
      if (title.contains('Space Rented')) return 'تم استئجار مساحة تخزينية';
      if (title.contains('Damaged Item Disposition Resolved')) return 'تم حسم معالجة المنتجات التالفة';
      if (title.contains('Wallet Payout Requested')) return 'تم طلب سحب الأرباح';
      if (title.contains('New Product Listed')) return 'تم إضافة منتج جديد للكتالوج';
      if (title.contains('Order Placed')) return 'تم استلام طلب جديد';
      if (title.contains('Order Confirmed')) return 'تم تأكيد الطلب';
      if (title.contains('Order Preparing')) return 'قيد تجهيز الطلب';
      if (title.contains('Ready for Shipment')) return 'جاهز للشحن والتسليم';
      if (title.contains('Order Delivered')) return 'تم تسليم الطلب بنجاح';
      return title;
    }
    return title;
  }

  String getDisplaySubtitle(bool isAr) {
    if (isAr) {
      if (subtitleAr != null && subtitleAr!.trim().isNotEmpty) return subtitleAr!;
      return subtitle
          .replaceAll('AED • PAID', 'درهم • تم السداد')
          .replaceAll('AED • PENDING', 'درهم • قيد الانتظار')
          .replaceAll(' • PAID', ' • تم السداد')
          .replaceAll(' • PENDING', ' • قيد الانتظار')
          .replaceAll(' • CONFIRMED', ' • مؤكد')
          .replaceAll(' • PREPARING', ' • قيد التجهيز')
          .replaceAll(' • READY_FOR_SHIPMENT', ' • جاهز للشحن')
          .replaceAll(' • SHIPPED', ' • تم الشحن')
          .replaceAll(' • DELIVERED', ' • تم التسليم')
          .replaceAll(' • CANCELLED', ' • ملغي')
          .replaceAll('PAID', 'تم السداد')
          .replaceAll('PENDING', 'قيد الانتظار')
          .replaceAll('CONFIRMED', 'مؤكد')
          .replaceAll('PREPARING', 'قيد التجهيز')
          .replaceAll('READY_FOR_SHIPMENT', 'جاهز للشحن')
          .replaceAll('SHIPPED', 'تم الشحن')
          .replaceAll('DELIVERED', 'تم التسليم')
          .replaceAll('Warehouse', 'مستودع')
          .replaceAll('Shelves', 'أرفف')
          .replaceAll('Shelf', 'رف')
          .replaceAll('items', 'عناصر')
          .replaceAll('item', 'عنصر')
          .replaceAll('To ', 'إلى ')
          .replaceAll('Disposition:', 'الإجراء:')
          .replaceAll('Database updated.', 'تم تحديث البيانات.')
          .replaceAll('database_', 'قاعدة البيانات')
          .replaceAll('refurbish', 'إعادة تجديد')
          .replaceAll('rtv_return', 'إرجاع للتاجر RTV')
          .replaceAll('quarantine', 'عزل تالف')
          .replaceAll('disposal', 'إتلاف مصرح')
          .replaceAll('Units', 'قطعة')
          .replaceAll('Dubai Central Warehouse', 'مستودع دبي المركزي')
          .replaceAll('Abu Dhabi Central Warehouse', 'مستودع أبوظبي المركزي')
          .replaceAll('Sharjah Regional Hub', 'مستودع الشارقة الإقليمي')
          .replaceAll('Al Ain Central Warehouse', 'مستودع العين المركزي')
          .replaceAll('Single/Multi Warehouse Booking', 'حجز مساحات تخزين متعددة')
          .replaceAll('Cold Brew Coffee', 'قهوة باردة')
          .replaceAll('AED', 'درهم');
    }
    return subtitle;
  }

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
      case ActivityType.inventory:
        return Icons.warning_amber_rounded;
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
      case ActivityType.inventory:
        return Colors.amber.shade800;
    }
  }

  // Serialization for Local Persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_ar': titleAr,
      'subtitle': subtitle,
      'subtitle_ar': subtitleAr,
      'date': date.toIso8601String(),
      'type': type.index, // Store enum index
      'amount': amount,
    };
  }

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    int typeIdx = 0;
    if (json['type'] is int) {
      typeIdx = (json['type'] as int).clamp(0, ActivityType.values.length - 1);
    }
    return DashboardActivity(
      id: (json['id'] as String?) ?? 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      title: (json['title'] as String?) ?? 'Activity Log',
      titleAr: json['title_ar'] as String?,
      subtitle: (json['subtitle'] as String?) ?? '',
      subtitleAr: json['subtitle_ar'] as String?,
      date: json['date'] != null ? (DateTime.tryParse(json['date'] as String) ?? DateTime.now()) : DateTime.now(),
      type: ActivityType.values[typeIdx],
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}
