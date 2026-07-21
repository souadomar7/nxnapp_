import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

/// NXN Postal Cash Payment — generates a unique barcode reference
/// the customer presents at any NXN Postal Office or Emirates Post branch.
class NxnCashPaymentPage extends StatefulWidget {
  final String orderId;
  final double amount;
  final String description;

  const NxnCashPaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.description,
  });

  @override
  State<NxnCashPaymentPage> createState() => _NxnCashPaymentPageState();
}

class _NxnCashPaymentPageState extends State<NxnCashPaymentPage> {
  late final String _referenceId;

  @override
  void initState() {
    super.initState();
    _referenceId = _generateReference();
    _saveToDb();
  }

  /// Generates a deterministic 12-char uppercase alphanumeric reference.
  String _generateReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final suffix = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'NXN-$suffix';
  }

  Future<void> _saveToDb() async {
    try {
      await Supabase.instance.client.from('cash_payment_references').upsert({
        'reference_id': _referenceId,
        'order_id': widget.orderId,
        'amount': widget.amount,
        'description': widget.description,
        'status': 'PENDING',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving cash payment reference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('NXN Cash Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A3C5E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Header Card ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3C5E), Color(0xFF2E63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E63FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_post_office_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text('Pay at NXN Postal Office',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'AED ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── QR Code ─────────────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Text('Scan or Show at Counter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    QrImageView(
                      data: _referenceId,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    // Reference text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _referenceId,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: Color(0xFF1A3C5E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _referenceId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reference ID copied!')),
                              );
                            },
                            child: Icon(Icons.copy_rounded, color: AppColors.bluePrimary, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Instructions ────────────────────────────────────────────────
            _InstructionList(),

            const SizedBox(height: 24),

            // ── Status indicator ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This reference is valid for 7 days. Your order will be confirmed within 30 minutes of payment.',
                      style: TextStyle(color: Colors.amber.shade800, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionList extends StatelessWidget {
  final _steps = const [
    (Icons.location_on_rounded, 'Visit any NXN Postal Office or Emirates Post branch'),
    (Icons.qr_code_scanner_rounded, 'Show the QR code or quote your reference ID above'),
    (Icons.payments_rounded, 'Pay the exact amount in cash (AED)'),
    (Icons.check_circle_rounded, 'Your order will be confirmed automatically within 30 minutes'),
  ];

  const _InstructionList();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How to Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            ..._steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${e.key + 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e.value.$2, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
