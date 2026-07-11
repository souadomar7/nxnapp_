import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'payment_page.dart';
import '../models/invoice.dart';
import '../services/marketplace_service.dart'; // Import service

import '../theme.dart';
import '../widgets/brand_logo.dart';

// Match other premium pages
class RequestDeliveryColors {
  static const primary = AppColors.bluePrimary; // Match App Theme
  static const background = Color(0xFFF3F6FB); // Light Grey-Blue
  static const textDark = Color(0xFF1A1F36); // Dark user text
  static const cardBorder = Color(0xFFE0E6F2);
}

class RequestDeliveryPage extends StatefulWidget {
  const RequestDeliveryPage({super.key});

  @override
  State<RequestDeliveryPage> createState() => _RequestDeliveryPageState();
}

class _RequestDeliveryPageState extends State<RequestDeliveryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _shippingCompany; // NXN / EMX
  String _deliveryType = 'Standard'; // Standard / Express
  bool _isInternational = false; // false = Domestic, true = International
  bool _isLoading = false;

  // Location related
  String? _localCity; // UAE emirate
  String? _country; // International country
  String? _internationalCity; // City in selected country

  // Domestic: 7 Emirates (Keys)
  final List<String> _uaeEmiratesKeys = const [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  // International countries and cities
  final Map<String, List<String>> _citiesByCountry = const {
    // Keeping countries in English for now as requested keys in batch 3 were limited
    'Qatar': ['Doha', 'Al Rayyan', 'Al Wakrah'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam', 'Khobar'],
    'Bahrain': ['Manama', 'Riffa'],
    'Oman': ['Muscat', 'Salalah', 'Sohar'],
    'UK': ['London', 'Manchester', 'Birmingham'],
    'Jordan': ['Amman', 'Irbid', 'Zarqa'],
    'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston'],
  };

  // Delivery Options Configuration Helper
  Map<String, List<Map<String, String>>> _getDeliveryOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'NXN': [
        {'id': 'Standard', 'label': l10n.standard, 'duration': l10n.days2to3, 'price': 'AED 25'},
        {'id': 'Express', 'label': l10n.express, 'duration': l10n.sameDay, 'price': 'AED 45'},
        {'id': 'Economy', 'label': l10n.economy, 'duration': l10n.days5to7, 'price': 'AED 15'},
      ],
      'EMX': [
        {'id': 'Premium', 'label': l10n.premium, 'duration': l10n.sameDay, 'price': 'AED 60'},
      ],
    };
  }

  String _getEmirateName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Dubai': return l10n.dubai;
      case 'Abu Dhabi': return l10n.abuDhabi;
      case 'Sharjah': return l10n.sharjah;
      case 'Al Ain': return l10n.alAin; // Though Al Ain is city, usually mapped to Abu Dhabi or self.
      // For others, return key or add more keys.
      // Reusing keys from Batch 2.
      // Missing keys for Ajman, etc. Returning key if not found or adding keys now?
      // I'll return key for now or add "ajman" etc to arb if needed.
      // Given scope, I'll rely on provided keys or fallback.
      default: return key; 
    }
  }

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_shippingCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectShippingCompanyError)),
      );
      return;
    }

    // Validate location based on mode
    if (!_isInternational && _localCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.selectCityError)),
      );
      return;
    }

    if (_isInternational && (_country == null || _internationalCity == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.selectCountryCityError)),
      );
      return;
    }

    final String locationString = !_isInternational
        ? _localCity!
        : '${_internationalCity!}, ${_country!}';

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); // simulate API

      // Create Invoice for Payment
      final invoice = Invoice(
        id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        number: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        warehouseName: 'Delivery Service ($_deliveryType)', 
        date: DateTime.now(),
        amount: 25.0, // Simplified fixed price for demo
        vat: 1.25,
        paid: false,
        type: InvoiceType.delivery,
        metaData: {
          'customerName': _recipientNameCtrl.text,
          'customerAddress': '$locationString\n${_addressCtrl.text}',
          'deliveryMethod': '$_shippingCompany - $_deliveryType',
        },
      );

      // Persist to DB
      try {
        await MarketplaceService().createInvoice(invoice);
      } catch (e) {
        debugPrint('Error saving invoice: $e');
      }

      // Navigate to Payment Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentsPage(initialInvoice: invoice)),
        );
      }
    } catch (_) {
      if (!mounted) return; // Add check before using context
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.requestFailedMessage)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RequestDeliveryColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: RequestDeliveryColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: const BrandLogo(height: 40),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.deliveryRequestTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.deliveryRequestSubtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: RequestDeliveryColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==== Shipping Options ====
                      _SectionHeader(title: AppLocalizations.of(context)!.shippingOptionsTitle),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RequestDeliveryColors.cardBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             _Label(AppLocalizations.of(context)!.shippingCompanyLabel),
                             const SizedBox(height: 8),
                             DropdownButtonFormField<String>(
                               decoration: _fieldDecoration(),
                               dropdownColor: Colors.white,
                               initialValue: _shippingCompany,
                               items: const [
                                 DropdownMenuItem(value: 'NXN', child: Text('NXN')),
                                 DropdownMenuItem(value: 'EMX', child: Text('EMX')),
                               ],
                               onChanged: (val) {
                                 if(val == null) return;
                                 setState(() {
                                   _shippingCompany = val;
                                   // Reset/Default delivery type to first option of new company
                                   _deliveryType = _getDeliveryOptions(context)[val]!.first['id']!;
                                 });
                               },
                               validator: (val) => val == null ? AppLocalizations.of(context)!.selectShippingCompanyError : null,
                             ),
                             const SizedBox(height: 20),

                             _Label(AppLocalizations.of(context)!.deliveryTypeLabel),
                             const SizedBox(height: 10),
                             
                             if (_shippingCompany == null)
                               Text(
                                 AppLocalizations.of(context)!.selectShippingCompanyFirst,
                                 style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                               )
                             else 
                               Row(
                                 children: _getDeliveryOptions(context)[_shippingCompany]!.map((opt) {
                                   final id = opt['id']!;
                                   final label = opt['label']!;
                                   return Expanded(
                                     child: Padding(
                                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                       child: _DeliveryTypeCard(
                                         label: label, 
                                         // duration and price removed
                                         isSelected: _deliveryType == id,
                                         onTap: () => setState(() => _deliveryType = id),
                                       ),
                                     ),
                                   );
                                 }).toList(),
                               ),
                             const SizedBox(height: 20),

                             _Label(AppLocalizations.of(context)!.deliveryModeLabel),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 Expanded(child: _RadioTile(
                                   label: AppLocalizations.of(context)!.domesticLabel, 
                                   icon: Icons.flag_rounded,
                                   isSelected: !_isInternational,
                                   onTap: () => setState(() {
                                      _isInternational = false;
                                      _localCity = null;
                                   }),
                                 )),
                                 const SizedBox(width: 12),
                                 Expanded(child: _RadioTile(
                                   label: AppLocalizations.of(context)!.internationalLabel, 
                                   icon: Icons.public_rounded,
                                   isSelected: _isInternational,
                                   onTap: () => setState(() {
                                      _isInternational = true;
                                      _country = null;
                                      _internationalCity = null;
                                   }),
                                 )),
                               ],
                             ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==== Location Section ====
                      _SectionHeader(title: AppLocalizations.of(context)!.deliveryLocationTitle),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RequestDeliveryColors.cardBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             if (!_isInternational) ...[
                               _Label(AppLocalizations.of(context)!.cityEmirateLabel),
                               const SizedBox(height: 8),
                               DropdownButtonFormField<String>(
                                 decoration: _fieldDecoration(),
                                 dropdownColor: Colors.white,
                                 initialValue: _localCity,
                                 items: _uaeEmiratesKeys.map((e) => DropdownMenuItem(value: e, child: Text(_getEmirateName(context, e)))).toList(),
                                 onChanged: (val) => setState(() => _localCity = val),
                                 validator: (val) => val == null ? AppLocalizations.of(context)!.selectCityError : null,
                               ),
                             ] else ...[
                               _Label(AppLocalizations.of(context)!.countryLabel),
                               const SizedBox(height: 8),
                               DropdownButtonFormField<String>(
                                 decoration: _fieldDecoration(),
                                 dropdownColor: Colors.white,
                                 initialValue: _country,
                                 items: _citiesByCountry.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                 onChanged: (val) => setState(() { _country = val; _internationalCity = null; }),
                                 validator: (val) => val == null ? AppLocalizations.of(context)!.selectCountryCityError : null,
                               ),
                               const SizedBox(height: 16),
                               _Label(AppLocalizations.of(context)!.cityLabel),
                               const SizedBox(height: 8),
                               DropdownButtonFormField<String>(
                                 decoration: _fieldDecoration(),
                                 dropdownColor: Colors.white,
                                 initialValue: _internationalCity,
                                 items: (_country == null ? <String>[] : _citiesByCountry[_country] ?? [])
                                     .map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                                 onChanged: (val) => setState(() => _internationalCity = val),
                                 validator: (val) {
                                   if (!_isInternational) return null;
                                   if (_country == null) return AppLocalizations.of(context)!.selectCountryCityError;
                                   if (val == null) return AppLocalizations.of(context)!.selectCityError;
                                   return null;
                                 },
                               ),
                             ],
                             const SizedBox(height: 16),
                             _Label(AppLocalizations.of(context)!.fullAddressLabel),
                             const SizedBox(height: 8),
                             _buildField(
                               controller: _addressCtrl,
                               icon: Icons.location_on_outlined,
                               maxLines: 2,
                               validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.enterAddressError : null,
                             ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==== Recipient Details ====
                      _SectionHeader(title: AppLocalizations.of(context)!.recipientDetailsTitle),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RequestDeliveryColors.cardBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(AppLocalizations.of(context)!.recipientNameLabel),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _recipientNameCtrl,
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.enterRecipientNameError : null,
                            ),
                            const SizedBox(height: 16),
                            _Label(AppLocalizations.of(context)!.phoneNumberLabel),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _recipientPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                              validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.enterPhoneNumberError : null,
                            ),
                            const SizedBox(height: 16),
                            _Label(AppLocalizations.of(context)!.notesLabel),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _notesCtrl,
                              icon: Icons.note_alt_outlined,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RequestDeliveryColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: RequestDeliveryColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(
                            AppLocalizations.of(context)!.submitRequestButton,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==== THEMED INPUT DECORATION ====
  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // Increased vertical padding
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEF2F6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RequestDeliveryColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: RequestDeliveryColors.textDark, fontWeight: FontWeight.w500),
      decoration: _fieldDecoration().copyWith(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// UI COMPONENTS
// --------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: RequestDeliveryColors.textDark,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14, // Increased from 13
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }
}

class _DeliveryTypeCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryTypeCard({
    required this.label, 
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8), 
        decoration: BoxDecoration(
          color: isSelected ? RequestDeliveryColors.primary : const Color(0xFFFAFBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? RequestDeliveryColors.primary : const Color(0xFFEEF2F6),
            width: isSelected ? 0 : 1
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: RequestDeliveryColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
        ),
        child: Center( // Center content
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.white : RequestDeliveryColors.textDark, 
              fontWeight: FontWeight.bold, 
              fontSize: 14 // Slightly increased from 13
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioTile({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: isSelected ? RequestDeliveryColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? RequestDeliveryColors.primary : const Color(0xFFEEF2F6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Use min size
          children: [
            Icon(icon, size: 20, color: isSelected ? RequestDeliveryColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Flexible( // Flexible to handle overflow
              child: Text(label,
                style: TextStyle(
                  color: isSelected ? RequestDeliveryColors.primary : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
