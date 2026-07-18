import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/invoice.dart';
import '../services/marketplace_service.dart';
import '../services/payment_service.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'receipt_page.dart';

class CheckoutPage extends StatefulWidget {
  final Invoice invoice;

  const CheckoutPage({super.key, required this.invoice});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  String _processingMessage = '';
  bool _paymentSuccess = false;
  bool _isCashOrderPlaced = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    return 'Generic';
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.card &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = _selectedMethod == PaymentMethod.cash
          ? 'Generating invoice slip...'
          : 'Contacting secure gateway...';
    });

    try {
      if (_selectedMethod == PaymentMethod.cash) {
        // Cash/Post Office: just register invoice as pending, show QR slip.
        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;
        setState(() => _processingMessage = 'Registering pending order...');
        await Future.delayed(const Duration(milliseconds: 1000));

        // Invoice was already saved as paid=false — nothing else to do here.
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _isCashOrderPlaced = true;
        });
        _animationController.forward();
      } else {
        // Card or Apple Pay — call real Stripe via our backend.
        setState(() => _processingMessage = 'Opening secure payment...');

        await PaymentService.pay(
          method: _selectedMethod,
          invoice: widget.invoice,
        );

        // Payment sheet completed successfully — update invoice + subscriptions.
        if (!mounted) return;
        setState(() => _processingMessage = 'Activating your space...');

        final service = MarketplaceService();
        try {
          if (widget.invoice.type == InvoiceType.rental &&
              widget.invoice.metaData != null) {
            final data = widget.invoice.metaData!;
            if (data.containsKey('warehouseIds')) {
              final List<dynamic> warehouseIds =
                  data['warehouseIds'] as List<dynamic>;
              for (var wId in warehouseIds) {
                final shelves = data['shelves_$wId'] ?? 5;
                final duration = data['duration_$wId'] ?? 1;
                await service.createSubscription(
                  wId.toString(),
                  shelves is num
                      ? shelves.toInt()
                      : int.tryParse(shelves.toString()) ?? 5,
                  duration is num
                      ? duration.toInt()
                      : int.tryParse(duration.toString()) ?? 1,
                  widget.invoice.total,
                );
              }
            } else {
              await service.createSubscription(
                data['primaryWarehouseId'] ?? 'unknown',
                data['shelves'] ?? 0,
                data['duration'] ?? 1,
                widget.invoice.total,
              );
            }
          } else if (widget.invoice.type == InvoiceType.delivery &&
              widget.invoice.metaData != null) {
            final data = widget.invoice.metaData!;
            await service.createDeliveryRequest(
              data['customerName'] ?? 'Unknown',
              data['customerAddress'] ?? 'Unknown',
              data['deliveryMethod'] ?? 'Standard',
            );
          }

          // The Stripe webhook will eventually also mark paid=true.
          // We also do it here for immediate UI feedback.
          await service.updateInvoiceStatus(widget.invoice.id, true);
        } catch (e) {
          debugPrint('Error activating subscription after payment: $e');
        }

        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _paymentSuccess = true;
        });
        _animationController.forward();
      }
    } on PaymentException catch (e) {
      // Stripe or server-level error — show a clear message.
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aedFormat = NumberFormat.currency(locale: 'en_AE', symbol: 'AED ', decimalDigits: 2);
    final cardType = _getCardType(_cardNumberController.text.replaceAll(' ', ''));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text(
              'Secure Checkout',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Order Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.invoice.warehouseName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bluePrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.invoice.number,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRowItem(l10n.subtotalLabel, aedFormat.format(widget.invoice.amount)),
                      _buildRowItem(l10n.vatLabel, aedFormat.format(widget.invoice.vat)),
                      if (widget.invoice.workerFee > 0)
                        _buildRowItem('Worker Assistance Fee', aedFormat.format(widget.invoice.workerFee)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          Text(
                            aedFormat.format(widget.invoice.total),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.bluePrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Select Payment Method Title
                Text(
                  l10n.choosePaymentMethod,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                // Payment Method Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodTab(
                        method: PaymentMethod.card,
                        icon: Icons.credit_card_rounded,
                        label: 'Card',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMethodTab(
                        method: PaymentMethod.applePay,
                        icon: Icons.apple,
                        label: 'Apple Pay',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMethodTab(
                        method: PaymentMethod.cash,
                        icon: Icons.local_post_office_rounded,
                        label: 'Post Office',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Payment details block
                if (_selectedMethod == PaymentMethod.card) ...[
                  // Visual Simulated Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cardType == 'Visa'
                            ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                            : cardType == 'Mastercard'
                                ? [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)]
                                : [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.contactless_outlined, color: Colors.white, size: 28),
                            Text(
                              cardType == 'Generic' ? 'Credit Card' : cardType,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _cardNumberController.text.isEmpty
                              ? '•••• •••• •••• ••••'
                              : _cardNumberController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CARDHOLDER', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'YOUR NAME'
                                      : _nameController.text.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('EXPIRES', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                const SizedBox(height: 2),
                                Text(
                                  _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card Details Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            prefixIcon: Icon(Icons.credit_card),
                            hintText: '4000 1234 5678 9010',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberFormatter(),
                          ],
                          onChanged: (v) => setState(() {}),
                          validator: (v) => (v == null || v.replaceAll(' ', '').length < 16) ? 'Enter valid 16-digit card number' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _CardExpiryFormatter(),
                                ],
                                onChanged: (v) => setState(() {}),
                                validator: (v) => (v == null || v.length < 5) ? 'Expiry required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '•••',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                validator: (v) => (v == null || v.length < 3) ? 'CVV required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Cardholder Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onChanged: (v) => setState(() {}),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedMethod == PaymentMethod.applePay) ...[
                  // Apple Pay Details Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.apple, size: 60, color: Colors.black),
                        const SizedBox(height: 12),
                        const Text(
                          'Apple Pay Checkout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Authenticate securely using FaceID/TouchID associated with your Apple Wallet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Post Office Cash Details Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_post_office_outlined, size: 60, color: Colors.orange),
                        const SizedBox(height: 12),
                        const Text(
                          'Emirates Post Office Payout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A booking invoice has been generated. You can present this invoice code at any Emirates Post outlet to complete payment in cash.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Pay Button
                ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                  child: Text(
                    _selectedMethod == PaymentMethod.cash
                        ? 'Confirm Cash Order'
                        : 'Pay ${aedFormat.format(widget.invoice.total)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Full Screen Loader/Portal simulator
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.75),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _processingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'PCI-DSS Secured Connection',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Full Screen Payment Success portal
        if (_paymentSuccess)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 80),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Payment Authorized (Sandbox)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'This is a simulated sandbox transaction. Real merchant integration is pending gateway deployment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Transaction ID: TXN-${widget.invoice.id.substring(0, min(widget.invoice.id.length, 6))}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to receipt
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReceiptPage(invoice: widget.invoice),
                          ),
                          result: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('View Tax Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Full Screen Cash Order Booked portal (For Post Office Payment Slip)
        if (_isCashOrderPlaced)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Invoice Generated',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please present this QR code to the teller at any Emirates Post Office to complete your cash payment and activate your space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: widget.invoice.number,
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invoice Ref: ${widget.invoice.number}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount Due: ${aedFormat.format(widget.invoice.total)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true); // Pop back and return true to refresh lists
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Done / Return to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRowItem(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMethodTab({required PaymentMethod method, required IconData icon, required String label}) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bluePrimary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.bluePrimary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
