import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/invoice.dart';

enum PaymentMethod { card, applePay, cash }

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}

class PaymentService {
  // -----------------------------------------------------------------------
  // Server URL — points to Supabase Edge Functions in production.
  // For local development: run `supabase functions serve` and use the local URL.
  // Set PAYMENT_SERVER_URL in your .env to the Supabase project functions URL:
  //   https://<project-ref>.supabase.co/functions/v1
  // -----------------------------------------------------------------------
  static const String _serverBaseUrl = String.fromEnvironment(
    'PAYMENT_SERVER_URL',
    defaultValue: 'http://localhost:54321/functions/v1',
  );

  // Path for the create-payment-intent Edge Function
  static const String _createIntentPath = '/create-payment-intent';

  /// Helper: Convert AED to fils (Stripe requires the smallest currency unit).
  static int toFils(double amountAED) => (amountAED * 100).round();

  /// Helper: Return total amount to charge.
  static double getInvoiceTotal(Invoice invoice) => invoice.total;

  // -----------------------------------------------------------------------
  // Unified payment entry point
  // -----------------------------------------------------------------------
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
        // Cash is handled entirely in the UI (shows invoice slip + QR).
        return;
    }
  }

  // -----------------------------------------------------------------------
  // Card Payment — creates a real Stripe PaymentIntent via our Node.js server
  // and presents the native flutter_stripe PaymentSheet.
  // -----------------------------------------------------------------------
  static Future<void> payWithCard({required Invoice invoice}) async {
    try {
      // 1. Get the Supabase session token to authenticate with our server
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        throw PaymentException(
          'You must be logged in to complete a card payment.',
        );
      }

      // 2. Request a PaymentIntent from the Supabase Edge Function
      final response = await http.post(
        Uri.parse('$_serverBaseUrl$_createIntentPath'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': toFils(invoice.total), // in fils
          'currency': 'aed',
          'invoiceId': invoice.id,
          'invoiceNumber': invoice.number,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw PaymentException(body['error'] ?? 'Failed to initiate payment.');
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw PaymentException('Invalid payment session received from server.');
      }

      // 3. Initialize the Stripe PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NXN Warehouses',
          style: ThemeMode.light,
        ),
      );

      // 4. Present the native payment sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // If we reach here without an exception, payment was confirmed by Stripe.
      // The webhook will asynchronously update `paid = true` in Supabase.
      debugPrint('✅ Stripe PaymentSheet completed for Invoice ${invoice.number}');
    } on StripeException catch (e) {
      final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment cancelled.';
      throw PaymentException(msg);
    } on PaymentException {
      rethrow;
    } catch (e) {
      // Network errors, server unreachable, etc.
      debugPrint('PaymentService card error: $e');
      throw PaymentException(
        'Unable to reach the payment server. Check your internet connection.',
      );
    }
  }

  // -----------------------------------------------------------------------
  // Apple Pay — delegates to payWithCard for now.
  // For native Apple Pay, use Stripe's payWithApplePay() when ready.
  // -----------------------------------------------------------------------
  static Future<void> payWithApplePay({required Invoice invoice}) async {
    return payWithCard(invoice: invoice);
  }
}
