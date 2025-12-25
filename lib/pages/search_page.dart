import 'package:flutter/material.dart';
import '../data/demo_warehouses.dart';
import '../models/warehouse.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/warehouse_card.dart';
import '../l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _q = TextEditingController();
  String emirate = 'All';
  double minShelves = 0;

  @override
  Widget build(BuildContext context) {
    final List<Warehouse> results = demoWarehouses.where((w) {
      final q = _q.text.toLowerCase();
      final matchesQuery = q.isEmpty || w.name.toLowerCase().contains(q) || (w.nameAr?.contains(q) ?? false);
      final matchesEmirate = emirate == 'All' || w.emirate == emirate;
      final matchesShelves = w.shelvesAvailable >= minShelves;
      return matchesQuery && matchesEmirate && matchesShelves;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.searchTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchFieldHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: AppLocalizations.of(context)!.emirateLabel,
                        value: emirate,
                        items: const ['All', 'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'RAK', 'UAQ', 'Fujairah', 'Al Ain'],
                        onChanged: (v) => setState(() => emirate = v ?? 'All'),
                        itemLabelBuilder: (e) {
                          final isAr = Localizations.localeOf(context).languageCode == 'ar';
                          if (!isAr) return e;
                          switch (e) {
                            case 'All': return 'الكل';
                            case 'Dubai': return 'دبي';
                            case 'Abu Dhabi': return 'أبو ظبي';
                            case 'Sharjah': return 'الشارقة';
                            case 'Ajman': return 'عجمان';
                            case 'RAK': return 'رأس الخيمة';
                            case 'UAQ': return 'أم القيوين';
                            case 'Fujairah': return 'الفجيرة';
                            case 'Al Ain': return 'العين';
                            default: return e;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTile(
                        label: '${AppLocalizations.of(context)!.minShelvesLabel}: ${minShelves.toInt()}',
                        value: minShelves,
                        min: 0,
                        max: 200,
                        onChanged: (v) => setState(() => minShelves = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 1, color: AppColors.border),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(AppLocalizations.of(context)!.resultsLabel, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...results.map((w) => WarehouseCard(w)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
