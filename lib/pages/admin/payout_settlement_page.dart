import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class PayoutSettlementPage extends StatefulWidget {
  const PayoutSettlementPage({super.key});
  @override
  State<PayoutSettlementPage> createState() => _PayoutSettlementPageState();
}

class _PayoutSettlementPageState extends State<PayoutSettlementPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ledgers = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadLedgers(); }

  Future<void> _loadLedgers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('payout_ledgers')
          .select('*, sme_sellers(business_name, contact_number, email)')
          .order('created_at', ascending: false);
      setState(() { _ledgers = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markPaid(String ledgerId) async {
    await _supabase.from('payout_ledgers').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
      'wps_batch_id': 'WPS-${DateTime.now().millisecondsSinceEpoch}',
    }).eq('id', ledgerId);
    _loadLedgers();
  }

  void _exportWpsCSV() {
    final pending = _ledgers.where((l) => l['status'] == 'pending').toList();
    // UAE WPS-compatible CSV format
    final buffer = StringBuffer();
    buffer.writeln('Employer_ID,Employee_Name,Bank_Code,Account_Number,Net_Amount,Currency,Reference');
    for (final l in pending) {
      final seller = l['sme_sellers'];
      buffer.writeln('NXN001,${seller?['business_name'] ?? ''},,TBD,${l['net_payout']?.toStringAsFixed(2) ?? '0.00'},AED,${l['id']}');
    }
    final csv = buffer.toString();
    Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('WPS CSV copied to clipboard — paste into your banking portal'),
        backgroundColor: Colors.indigo,
      ));
    }
  }

  Color _statusColor(String? s) {
    switch(s) {
      case 'pending': return Colors.orange;
      case 'processing': return AppColors.bluePrimary;
      case 'paid': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final totalPending = _ledgers
        .where((l) => l['status'] == 'pending')
        .fold(0.0, (sum, l) => sum + ((l['net_payout'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isAr ? '💰 تسوية المدفوعات' : '💰 Payout Settlement',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _exportWpsCSV,
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: Text(isAr ? 'تصدير WPS' : 'Export WPS',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.bluePrimary),
                  child: Column(
                    children: [
                      Text(isAr ? 'إجمالي المدفوعات المعلقة' : 'Total Pending Payouts',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('AED ${totalPending.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Expanded(
                  child: _ledgers.isEmpty
                      ? Center(child: Text(isAr ? 'لا توجد سجلات دفع' : 'No payout records',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ledgers.length,
                          itemBuilder: (ctx, i) {
                            final l = _ledgers[i];
                            final seller = l['sme_sellers'];
                            final status = l['status'] as String?;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,4))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(seller?['business_name'] ?? 'Merchant',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(status ?? '',
                                              style: TextStyle(color: _statusColor(status),
                                                  fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Fee breakdown
                                    _FeeRow(isAr ? 'إجمالي المبيعات' : 'Gross Sales',
                                        'AED ${(l['gross_sales'] as num?)?.toStringAsFixed(2) ?? "0.00"}'),
                                    _FeeRow(isAr ? 'عمولة المنصة (5%)' : 'Platform Fee (5%)',
                                        '- AED ${(l['platform_commission'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                                        isDeduction: true),
                                    _FeeRow(isAr ? 'رسوم تخزين' : 'Storage Fees',
                                        '- AED ${(l['storage_fees'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                                        isDeduction: true),
                                    _FeeRow(isAr ? 'ضريبة القيمة المضافة (5%)' : 'VAT (5%)',
                                        '- AED ${(l['vat_amount'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                                        isDeduction: true),
                                    const Divider(),
                                    _FeeRow(
                                      isAr ? '💰 صافي المبلغ المستحق' : '💰 Net Payout',
                                      'AED ${(l['net_payout'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                                      isBold: true,
                                    ),
                                    if (status == 'pending') ...([
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _markPaid(l['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(isAr ? 'تأكيد الدفع ✓' : 'Mark as Paid ✓'),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDeduction;
  final bool isBold;
  const _FeeRow(this.label, this.value, {this.isDeduction = false, this.isBold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isBold ? 14 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? AppColors.textPrimary : Colors.grey.shade600,
        )),
        Text(value, style: TextStyle(
          fontSize: isBold ? 15 : 13,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
          color: isDeduction ? Colors.red.shade700 : (isBold ? Colors.green.shade700 : AppColors.textPrimary),
        )),
      ],
    ),
  );
}
