import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nxnapp/l10n/app_localizations.dart';
import 'package:nxnapp/models/invoice.dart';
import 'package:nxnapp/theme.dart';
import 'package:nxnapp/widgets/brand_logo.dart';
import 'package:nxnapp/widgets/common.dart';

class ReceiptPage extends StatelessWidget {
  final Invoice invoice;

  const ReceiptPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aed = NumberFormat.currency(
      locale: 'en_AE',
      symbol: 'AED ',
      decimalDigits: 2,
    );


    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(l10n.receiptPageTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Receipt Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header (Logo + Tax Invoice)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const BrandLogo(height: 32),
                        const SizedBox(height: 16),
                        Text(
                          l10n.taxInvoiceLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.paymentSuccessful,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Receipt Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor Details
                        _KeyValuePair(
                          label: l10n.vendorName,
                          value: '${l10n.vendorAddress}\n${l10n.trnLabel}: 100234567890003',
                          isMultiLine: true,
                        ),
                        const Divider(height: 32),

                        // Bill To (Placeholder for now)
                        _KeyValuePair(
                          label: l10n.billToLabel,
                          value: 'Suad Sayed\nsuadsayed@example.com', // Would normally come from user profile
                          isMultiLine: true,
                        ),
                        const Divider(height: 32),

                        // Transaction Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _KeyValuePair(label: l10n.dateLabel, value: invoice.formattedDate)),
                            Expanded(child: _KeyValuePair(label: l10n.transactionIdLabel, value: 'TXN-${invoice.id.length >= 6 ? invoice.id.substring(0, 6) : invoice.id}')), // Mock TXN ID
                          ],
                        ),
                        const SizedBox(height: 20),
                         _KeyValuePair(label: l10n.invoiceTitle(invoice.number), value: ''),

                        const Divider(height: 32),

                        // Line Items Header
                        Row(
                          children: [
                             Expanded(flex: 2, child: Text(l10n.itemDescription, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                             Expanded(child: Text(l10n.amountLabel, textAlign: TextAlign.end, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Line Items (Derived from Invoice)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                               invoice.warehouseName,
                               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                aed.format(invoice.amount), // Base amount before VAT
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        const Divider(height: 32),

                        // Totals
                        _BillingRow(label: l10n.subtotalLabel, value: aed.format(invoice.amount)),
                        _BillingRow(label: l10n.vatLabel, value: aed.format(invoice.vat)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEAECF0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(l10n.totalPaid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               Text(aed.format(invoice.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.bluePrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zig-zag bottom (visual flair for receipt)
                  // ... omitted for simplicity, just rounded corners
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: l10n.closeButton,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValuePair extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiLine;

  const _KeyValuePair({required this.label, required this.value, this.isMultiLine = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        if (value.isNotEmpty)
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String value;
  const _BillingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          )),
          Text(value, style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          )),
        ],
      ),
    );
  }
}
