import 'package:flutter/material.dart';
import '../models/warehouse.dart';

import '../l10n/app_localizations.dart';

void showQuoteSheet(BuildContext context, Warehouse w) {
  // Default: 1 unit (room / rack / space)
  final unitsController = TextEditingController(text: '1');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.instantQuoteTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🔢 Units instead of Area (m²)
          TextField(
            controller: unitsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration( // const removed because of dynamic access
              labelText: AppLocalizations.of(context)!.unitsLabel,
              helperText: AppLocalizations.of(context)!.unitsHelper,
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Parse units; fallback to 1 if invalid
                final parsed = int.tryParse(unitsController.text.trim());
                final units = (parsed == null || parsed <= 0) ? 1 : parsed;

                // Treat pricePerShelf as price per unit per month
                final subtotal = units * w.pricePerShelf;      // monthly baseline
                final platformFee = subtotal * 0.05;           // 5% platform fee
                final vat = (subtotal + platformFee) * 0.05;   // UAE VAT 5%
                final total = subtotal + platformFee + vat;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.estimatedTotalTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _priceRow(AppLocalizations.of(context)!.unitsLabel, units.toString(), isPlainText: true),
                        const SizedBox(height: 4),
                        _priceRow(AppLocalizations.of(context)!.subtotalLabel, subtotal),
                        _priceRow(AppLocalizations.of(context)!.platformFeeLabel, platformFee),
                        _priceRow(AppLocalizations.of(context)!.vatLabel, vat),
                        const Divider(),
                        _priceRow(AppLocalizations.of(context)!.totalAedLabel, total, bold: true),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.closeButton),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: connect this to your Payments / Next step
                        },
                        child: Text(AppLocalizations.of(context)!.continueButton),
                      ),
                    ],
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.calculateButton),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _priceRow(String label, dynamic value,
    {bool bold = false, bool isPlainText = false}) {
  final style = TextStyle(
    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
  );

  final String valueText = isPlainText
      ? value.toString()
      : 'AED ${(value as double).toStringAsFixed(2)}';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(valueText, style: style),
      ],
    ),
  );
}
