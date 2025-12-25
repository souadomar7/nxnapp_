import 'package:flutter/foundation.dart';
// for kIsWeb, etc
import '../models/invoice.dart';

enum PaymentMethod { card, applePay, cash }

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

class PaymentService {
 
  
  /// Helper: return total amount to charge (e.g. amount + VAT).
  static double getInvoiceTotal(Invoice invoice) {
    return invoice.amount + invoice.vat;
  }

  /// Helper: convert AED -> fils (Stripe etc. usually require int).
  static int toFils(double amountAED) {
    return (amountAED * 100).round();
  }

  /// High-level unified payment call.
  static Future<void> pay({
    required PaymentMethod method,
    required Invoice invoice,
  }) async {
    switch (method) {
      case PaymentMethod.card:
        return payWithCard(invoice: invoice);
      case PaymentMethod.applePay:
        return payWithApplePay(invoice: invoice);
      case PaymentMethod.cash:
        // Handled in UI for now, or add a service call if needed.
        return;
    }
  }

  /// Card payment using backend and Stripe PaymentSheet
  static Future<void> payWithCard({
    required Invoice invoice,
  }) async {
    // MOCK PAYMENT IMPLEMENTATION (Provider removed for development speed)
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    debugPrint('Payment Provider bypassed: Payment successful for Invoice ${invoice.number}');
    return;
  }

  /// Placeholder for Apple Pay (requires specific backend setup)
  static Future<void> payWithApplePay({
    required Invoice invoice,
  }) async {
    // throw PaymentException('Apple Pay implementation requires backend support.');
    await payWithCard(invoice: invoice); // Fallback to card for now
  }
}
