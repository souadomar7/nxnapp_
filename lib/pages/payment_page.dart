import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import '../widgets/common.dart';
import '../theme.dart';
import '../services/payment_service.dart';
import '../l10n/app_localizations.dart';
import '../pages/receipt_page.dart';
import '../services/marketplace_service.dart';
import '../widgets/brand_logo.dart';



class PaymentsPage extends StatefulWidget {

  final Invoice? initialInvoice;

  const PaymentsPage({super.key, this.initialInvoice});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _aed =
  NumberFormat.currency(locale: 'en_AE', symbol: 'AED ', decimalDigits: 2);

  // Simple filter: All / Paid / Pending
  String _statusFilter = 'All';
  final _statusOptions = const ['All', 'Paid', 'Pending'];
  
  // Real Data
  final MarketplaceService _marketService = MarketplaceService();
  final List<Invoice> _invoices = [];


  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }
  
  Future<void> _loadInvoices() async {

    try {
      final list = await _marketService.getInvoices();
      
      // If we arrived with an initialInvoice that might not be in the list yet 
      // (due to async race or if we decide not to rely on immediate fetch),
      // we can manually add it. But ideally, it was persisted before navigation.
      // Let's assume persistence worked.
      
      // Check if incoming invoice exists in fetched list. 
      // If not (maybe latency), add it at top.
      if (widget.initialInvoice != null) {
        final exists = list.any((e) => e.id == widget.initialInvoice!.id);
        if (!exists) {
          list.insert(0, widget.initialInvoice!);
        }
      }
      
      setState(() {
        _invoices.clear();
        _invoices.addAll(list);
      });
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {

    }
  }

  List<Invoice> get _filtered {
    if (_statusFilter == 'All') return _invoices;
    if (_statusFilter == 'Paid') {
      return _invoices.where((e) => e.paid).toList();
    }
    return _invoices.where((e) => !e.paid).toList();
  }

  // Web-safe Apple Pay availability check
  bool get _applePayAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _choosePaymentMethod(Invoice inv) async {
    final method = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                   const Icon(Icons.payment_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.choosePaymentMethod,
                      style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card
              ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.bluePrimary),
                title: Text(AppLocalizations.of(context)!.payByCard),
                 onTap: () => Navigator.pop(context, PaymentMethod.card),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),

              // Cash on Post Office
              ListTile(
               leading: const Icon(Icons.local_post_office_outlined, color: Colors.orange),
               title: Text(AppLocalizations.of(context)!.cashOnPostOffice),
               subtitle: Text(AppLocalizations.of(context)!.payAtPostOfficeSubtitle),
               onTap: () => Navigator.pop(context, PaymentMethod.cash),
               shape: RoundedRectangleBorder(
                 side: BorderSide(color: AppColors.border),
                 borderRadius: BorderRadius.circular(12),
               ),
              ),
              const SizedBox(height: 10),

              // Apple Pay
              if (_applePayAvailable)
                ListTile(
                  leading: const Icon(Icons.phone_iphone_rounded, color: Colors.black),
                  title: Text(AppLocalizations.of(context)!.applePay),
                  onTap: () => Navigator.pop(context, PaymentMethod.applePay),
                   shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || method == null) return;

    switch (method) {
      case PaymentMethod.card:
        await _handleCardPay(inv);
        break;
      case PaymentMethod.applePay:
        await _handleApplePay(inv);
        break;
      case PaymentMethod.cash:
        // Cash payment simulation
        _markInvoicePaid(inv.id);
         _toast(AppLocalizations.of(context)!.orderPlacedPostOffice);
        // pop back to finding space or home
        Navigator.pop(context);
        break;
    }
  }

  Future<void> _handleCardPay(Invoice inv) async {
    try {
      _showProgress(AppLocalizations.of(context)!.processingPayment);
      await PaymentService.payWithCard(invoice: inv);
      if (!mounted) return;
      Navigator.pop(context); // close progress
      await _processActivityLog(inv); // Log activity before navigation
      _markInvoicePaid(inv.id);
      
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.paymentSuccessful);
      
      // Return to Dashboard/Previous
      Navigator.pop(context); 

    } on PaymentException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _toast(e.message);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        _toast(AppLocalizations.of(context)!.cardError);
      }
    }
  }

  Future<void> _handleApplePay(Invoice inv) async {
    try {
      _showProgress(AppLocalizations.of(context)!.openingApplePay);
      await PaymentService.payWithApplePay(invoice: inv);
      if (!mounted) return;
      Navigator.pop(context); // close progress
      await _processActivityLog(inv); // Log activity
      _markInvoicePaid(inv.id);
      
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.applePaySuccess);
      
      // Return to Dashboard/Previous
      Navigator.pop(context);

    } on PaymentException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _toast(e.message);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        _toast(AppLocalizations.of(context)!.applePayError);
      }
    }
  }

  Future<void> _markInvoicePaid(String id) async {
    // 1. Update UI (Optimistic)
    final idx = _invoices.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final old = _invoices[idx];
      _invoices[idx] = Invoice(
        id: old.id,
        number: old.number,
        warehouseName: old.warehouseName,
        date: old.date,
        amount: old.amount,
        vat: old.vat,
        paid: true,
        type: old.type,
        metaData: old.metaData,
      );
      setState(() {});
      
      // 2. Persist
      try {
        await _marketService.updateInvoiceStatus(id, true);
      } catch (e) {
        debugPrint('Error updating invoice status: $e');
        // Revert? For now, keep optimistic.
      }
    }
  }

  void _showProgress(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showInvoiceDialog(BuildContext context, Invoice inv) async {
    final statusTag = Tag(inv.paid
        ? AppLocalizations.of(context)!.paidTag
        : AppLocalizations.of(context)!.pendingTag);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.invoiceTitle(inv.number)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statusTag,
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.warehouseProductLabel}: ${inv.warehouseName}'),
            Text('${AppLocalizations.of(context)!.dateLabel}: ${inv.formattedDate}'),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300),
            _kv(AppLocalizations.of(context)!.subtotalLabel, _aed.format(inv.amount)),
            _kv(AppLocalizations.of(context)!.vatLabel, _aed.format(inv.vat)),
            if (inv.workerFee > 0)
              _kv('Worker Fees', _aed.format(inv.workerFee)),
            const Divider(),
            _kv(AppLocalizations.of(context)!.totalLabel, _aed.format(inv.total), bold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
          PrimaryButton(
            text: inv.paid ? AppLocalizations.of(context)!.viewReceipt : AppLocalizations.of(context)!.payNow,
            onPressed: () {
              Navigator.pop(context);
              if (inv.paid) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReceiptPage(invoice: inv)),
                );
              } else {
                _choosePaymentMethod(inv);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: CustomScrollView(
        slivers: [
          // 1. Premium Blue Header
          SliverAppBar(
            expandedHeight: 170, // Increased for better spacing
            pinned: true,
            backgroundColor: AppColors.bluePrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 50), // Increased bottom padding to clear overlap
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Center(child: BrandLogo(height: 28)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.paymentsTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.invoicesFoundCount(invoices.length),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
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
                color: Color(0xFFF3F6FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              transform: Matrix4.translationValues(0, -24, 0), // Adjusted overlap
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40), // Adjusted top padding
                child: Column(
                  children: [
                    // Filter Chips (User Friendly & Compact)
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _statusOptions[index];
                          final isSelected = _statusFilter == status;
                          return InkWell(
                            onTap: () => setState(() => _statusFilter = status),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.bluePrimary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.bluePrimary : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                status == 'All' ? AppLocalizations.of(context)!.all : 
                                status == 'Paid' ? AppLocalizations.of(context)!.paidTag : 
                                AppLocalizations.of(context)!.pendingTag,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (invoices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                             Text(
                              AppLocalizations.of(context)!.noInvoicesTitle,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                             const SizedBox(height: 8),
                             Text(
                              AppLocalizations.of(context)!.noInvoicesSubtitle,
                              textAlign: TextAlign.center,
                               style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...invoices.map(
                            (inv) => _InvoiceCard(
                          invoice: inv,
                          aed: _aed,
                          onView: () => _showInvoiceDialog(context, inv),
                          onPay: inv.paid ? null : () => _choosePaymentMethod(inv),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    final style =
    TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: style),
          Text(v, style: style),
        ],
      ),
    );
  }

  Future<void> _processActivityLog(Invoice inv) async {
    // Only proceed if authenticated and we have metadata
    final service = MarketplaceService();
    
    if (inv.type == InvoiceType.rental && inv.metaData != null) {
      final data = inv.metaData!;
      // 'primaryWarehouseId', 'shelves', 'duration'
      await service.createSubscription(
        data['primaryWarehouseId'] ?? 'unknown', 
        data['shelves'] ?? 0, 
        data['duration'] ?? 1, 
        inv.total
      );
    } else if (inv.type == InvoiceType.delivery && inv.metaData != null) {
      final data = inv.metaData!;
      // 'customerName', 'customerAddress', 'deliveryMethod'
      await service.createDeliveryRequest(
        data['customerName'] ?? 'Unknown', 
        data['customerAddress'] ?? 'Unknown', 
        data['deliveryMethod'] ?? 'Standard'
      );
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat aed;
  final VoidCallback onView;
  final VoidCallback? onPay;

  const _InvoiceCard({
    required this.invoice,
    required this.aed,
    required this.onView,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // 1. Status Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: invoice.paid ? Colors.green.withValues(alpha: 0.1) : AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  invoice.paid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                  color: invoice.paid ? Colors.green : AppColors.bluePrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.warehouseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1F36)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${invoice.number} • ${invoice.formattedDate}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              
              // 3. Amount & Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    aed.format(invoice.total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: invoice.paid ? Colors.green.shade700 : const Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!invoice.paid)
                    SizedBox(
                      height: 24,
                      child: ElevatedButton(
                        onPressed: onPay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.payNow,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                     Text(
                      AppLocalizations.of(context)!.paidTag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
