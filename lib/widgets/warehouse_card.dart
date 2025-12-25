import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import '../theme.dart';
import '../pages/warehouse_detail_page.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class WarehouseCard extends StatelessWidget {
  final Warehouse w;
  const WarehouseCard(this.w, {super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WarehouseDetailPage(w: w)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.warehouse_rounded, color: AppColors.bluePrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? (w.nameAr ?? w.name) : w.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                            AppLocalizations.of(context)!
                                .emirateAndShelves(
                                    w.shelvesAvailable, isAr ? (w.emirateAr ?? w.emirate) : w.emirate),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Tag(w.is24h
                      ? AppLocalizations.of(context)!.access247
                      : AppLocalizations.of(context)!.businessHours),
                  const SizedBox(width: 6),
                  Tag(AppLocalizations.of(context)!
                      .pricePerShelf(w.pricePerShelf.toStringAsFixed(0))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
