import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/marketplace_service.dart';

class RestockPage extends StatefulWidget {
  const RestockPage({super.key});

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final itemName = _itemNameCtrl.text.trim();
      final qty = int.parse(_quantityCtrl.text.trim());
      // Combine item name into notes as backend doesn't have item_name column for requests yet
      final notes = "Item: $itemName\n${_notesCtrl.text.trim()}";

      // Using createDropOffRequest for restock
      await MarketplaceService().createDropOffRequest(
        DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
        qty,
        notes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.restockCreated)),
      );
      Navigator.pop(context); // Return to previous screen

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.restockFailed)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.restockBtn),
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(AppLocalizations.of(context)!.itemNameLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameCtrl,
                decoration: _fieldDecoration(hint: 'e.g. Widget A'),
                validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.enterItemNameError : null,
              ),
              const SizedBox(height: 20),

              _buildLabel(AppLocalizations.of(context)!.quantityLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityCtrl,
                decoration: _fieldDecoration(hint: 'e.g. 50'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppLocalizations.of(context)!.enterQuantityError;
                  if (int.tryParse(v) == null) return AppLocalizations.of(context)!.mustBeNumberError;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel(AppLocalizations.of(context)!.notesOptionalLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                decoration: _fieldDecoration(hint: AppLocalizations.of(context)!.additionalDetailsHint),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context)!.restockBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1F36),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E6F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
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
}
