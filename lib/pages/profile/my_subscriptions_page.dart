import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/history_models.dart';
import '../request_delivery_page.dart';
import '../booking_page.dart';
import 'wallet_page.dart';

enum RefundPolicyModel { strictNonRefundable, partialWithFee, recalculateStandard }

class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final user = _supabase.auth.currentUser;
    List<Map<String, dynamic>> list = [];

    if (user != null) {
      try {
        final res = await _supabase
            .from('sme_subscriptions')
            .select('*, warehouses(name, emirate)')
            .eq('seller_id', user.id)
            .order('end_date', ascending: true);
        list = List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('Error loading DB subscriptions: $e');
      }
    }

    // Default active demo subscription for test user / demo merchant
    if (list.isEmpty) {
      list = [
        {
          'id': 'SUB-DXB-9921',
          'warehouse_name': 'Dubai Central Hub (Dubai South)',
          'shelves_count': 2,
          'storage_mode': 'Ambient Storage (25°C)',
          'monthly_fee': 200.0,
          'total_paid': 600.0, // 3-month package @ 200 AED/mo for 2 shelves
          'discounted_paid': 510.0, // 15% 3-month discount term
          'duration_months': 3,
          'start_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
          'is_active': true,
          'auto_renew': true,
          'cancellation_pending': false,
        },
      ];
    }

    if (mounted) {
      setState(() {
        _subscriptions = list;
        _isLoading = false;
      });
    }
  }

  void _openCancellationPolicyModal(int index, bool isAr) {
    final sub = _subscriptions[index];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CancellationPolicyModal(
        subscription: sub,
        isAr: isAr,
        onConfirmCancel: (policyModel, refundAmount) async {
          Navigator.pop(ctx);
          await _processCancellationWithPolicy(index, sub['id'].toString(), policyModel, refundAmount, isAr);
        },
      ),
    );
  }

  Future<void> _processCancellationWithPolicy(
    int index,
    String subId,
    RefundPolicyModel policyModel,
    double refundAmount,
    bool isAr,
  ) async {
    setState(() {
      _subscriptions[index]['auto_renew'] = false;
      _subscriptions[index]['cancellation_pending'] = true;
      _subscriptions[index]['refund_amount'] = refundAmount;
    });

    final policyStr = policyModel.toString().split('.').last;
    final res = await _marketplaceService.requestSubscriptionCancellation(
      subscriptionId: subId,
      refundModel: policyStr,
      refundAmount: refundAmount,
    );

    final effectiveStr = res['effective_end_date'] != null
        ? res['effective_end_date'].toString().split('T').first
        : DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T').first;

    setState(() {
      _subscriptions[index]['auto_renew'] = false;
      _subscriptions[index]['cancellation_pending'] = true;
      _subscriptions[index]['refund_amount'] = refundAmount;
      _subscriptions[index]['end_date'] = effectiveStr;
    });

    // Log Activity
    final policyName = policyModel == RefundPolicyModel.strictNonRefundable
        ? 'Model A (Non-Refundable)'
        : (policyModel == RefundPolicyModel.partialWithFee ? 'Model B (Partial Refund)' : 'Model C (Standard Rate Recalc)');

    await _marketplaceService.addActivity(
      DashboardActivity(
        id: 'ACT-SUB-CANCEL-${DateTime.now().millisecondsSinceEpoch}',
        title: isAr ? 'تم طلب إلغاء الاشتراك ($policyName)' : 'Subscription Cancellation ($policyName)',
        subtitle: isAr
            ? 'تم إضافة استرداد بقيمة $refundAmount درهم إلى المحفظة. يرجى جدولة خروج المخزون.'
            : 'AED ${refundAmount.toStringAsFixed(2)} credited to Merchant Wallet. Schedule inventory outbound.',
        date: DateTime.now(),
        type: ActivityType.rental,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr
                    ? 'تم تأكيد الإلغاء! تم رصيد ${refundAmount.toStringAsFixed(2)} د.إ في محفظتك 💰'
                    : 'Cancellation confirmed! AED ${refundAmount.toStringAsFixed(2)} credited to your Wallet 💰',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                isAr ? 'يمكنك جدولة خروج البضائع قبل انقضاء المدة.' : 'You can schedule outbound goods dispatch anytime before exit date.',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          action: SnackBarAction(
            label: isAr ? 'المحفظة' : 'View Wallet',
            textColor: Colors.amber,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletPage()),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _reactivateSubscription(int index, String subId, bool isAr) async {
    setState(() {
      _subscriptions[index]['auto_renew'] = true;
      _subscriptions[index]['cancellation_pending'] = false;
      _subscriptions[index]['is_active'] = true;
    });

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('sme_subscriptions').update({
          'auto_renew': true,
          'is_active': true,
        }).eq('id', subId);
      } catch (e) {
        debugPrint('Error reactivating sub: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade800,
          content: Text(
            isAr ? 'تم إعادة تفعيل التجديد التلقائي للاشتراك بنجاح! ⚡' : 'Subscription reactivated & auto-renew enabled! ⚡',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isAr ? 'اشتراكاتي وسياسة الإلغاء' : 'Subscriptions & Refund Policy'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            tooltip: isAr ? 'استئجار رفوف إضافية' : 'Rent More Shelves',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'سياسة استرداد الإلغاء المعتمدة' : 'Cancellation & Refund Policies',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? 'احتساب دقيق للاسترداد المالي وإعادة رصيد المحفظة' : 'Transparent early exit models & merchant wallet credits',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  isAr ? 'الاشتراكات الحالية (${_subscriptions.length})' : 'Active Subscriptions (${_subscriptions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),

                const SizedBox(height: 12),

                ...List.generate(_subscriptions.length, (index) {
                  final sub = _subscriptions[index];
                  final bool isPendingCancel = sub['cancellation_pending'] == true || sub['auto_renew'] == false;
                  final bool isActive = sub['is_active'] == true && !isPendingCancel;
                  final warehouseName = sub['warehouse_name'] ?? sub['warehouses']?['name'] ?? 'Dubai Central Hub';
                  final shelvesCount = sub['shelves_count'] ?? 2;
                  final storageMode = sub['storage_mode'] ?? 'Ambient Storage (25°C)';
                  final monthlyFee = (sub['monthly_fee'] as num?)?.toDouble() ?? 200.0;
                  final refundAmount = (sub['refund_amount'] as num?)?.toDouble() ?? 0.0;
                  final endDateStr = sub['end_date'].toString().split('T').first;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPendingCancel
                            ? Colors.amber.shade300
                            : AppColors.border,
                        width: isPendingCancel ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                warehouseName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade50
                                    : (isPendingCancel ? Colors.amber.shade50 : Colors.red.shade50),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.shade300
                                      : (isPendingCancel ? Colors.amber.shade300 : Colors.red.shade300),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle_rounded
                                        : (isPendingCancel ? Icons.hourglass_top_rounded : Icons.cancel_rounded),
                                    size: 13,
                                    color: isActive
                                        ? Colors.green.shade700
                                        : (isPendingCancel ? Colors.amber.shade900 : Colors.red.shade700),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActive
                                        ? (isAr ? 'نشط ومفعل ⚡' : 'Active ⚡')
                                        : (isPendingCancel
                                            ? (isAr ? 'مجدول للإلغاء ⏳' : 'Cancellation Scheduled ⏳')
                                            : (isAr ? 'ملغى' : 'Cancelled')),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.green.shade800
                                          : (isPendingCancel ? Colors.amber.shade900 : Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Specs Grid
                        Row(
                          children: [
                            Expanded(child: _subSpec(isAr ? 'عدد الأرفف' : 'Shelves Leased', '$shelvesCount Shelves')),
                            Expanded(child: _subSpec(isAr ? 'نمط التبريد' : 'Storage Class', storageMode)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _subSpec(isAr ? 'التكلفة الشهرية' : 'Monthly Rate', 'AED ${monthlyFee.toStringAsFixed(0)} / mo')),
                            Expanded(child: _subSpec(isAr ? 'تاريخ الانتهاء' : 'Expiry Date', endDateStr)),
                          ],
                        ),

                        // Pending Cancellation Alert Banner inside Card
                        if (isPendingCancel) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade900),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr ? 'ملخص الاسترداد المالي للإلغاء' : 'Cancellation Refund Summary',
                                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isAr
                                      ? 'تم اعتماد استرداد مالي بقيمة ${refundAmount.toStringAsFixed(2)} د.إ وتغذية المحفظة بها. ينتهي الوصول بتاريخ $endDateStr.'
                                      : 'AED ${refundAmount.toStringAsFixed(2)} refund was credited to your Wallet. Storage access active until $endDateStr.',
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Action Buttons Row
                        Row(
                          children: [
                            if (isActive) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openCancellationPolicyModal(index, isAr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: Text(isAr ? 'إلغاء واحتساب Refund' : 'Cancel & Calculate Refund', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RequestDeliveryPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.bluePrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
                                  label: Text(isAr ? 'خروج البضائع 🚚' : 'Outbound Goods 🚚', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ] else if (isPendingCancel) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _reactivateSubscription(index, sub['id'].toString(), isAr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                  label: Text(isAr ? 'إعادة تفعيل ⚡' : 'Reactivate Auto-Renew ⚡', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RequestDeliveryPage()),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.bluePrimary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.local_shipping_rounded, size: 16),
                                  label: Text(isAr ? 'سحب المخزون' : 'Schedule Outbound', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _subSpec(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3 POLICY MODELS CANCELLATION MODAL
// ─────────────────────────────────────────────────────────────────────────────

class _CancellationPolicyModal extends StatefulWidget {
  final Map<String, dynamic> subscription;
  final bool isAr;
  final Function(RefundPolicyModel model, double refundAmount) onConfirmCancel;

  const _CancellationPolicyModal({
    required this.subscription,
    required this.isAr,
    required this.onConfirmCancel,
  });

  @override
  State<_CancellationPolicyModal> createState() => _CancellationPolicyModalState();
}

class _CancellationPolicyModalState extends State<_CancellationPolicyModal> {
  RefundPolicyModel _selectedModel = RefundPolicyModel.partialWithFee; // Recommended Model B

  double get _paidAmount => (widget.subscription['total_paid'] as num?)?.toDouble() ?? 600.0;
  double get _discountedPaid => (widget.subscription['discounted_paid'] as num?)?.toDouble() ?? 510.0;
  int get _shelvesCount => (widget.subscription['shelves_count'] as num?)?.toInt() ?? 2;

  double get _calculatedRefund {
    switch (_selectedModel) {
      case RefundPolicyModel.strictNonRefundable:
        // Policy A: Remaining months forfeited -> 0 AED refund
        return 0.0;

      case RefundPolicyModel.partialWithFee:
        // Policy B: Example (Paid 600 AED, Used 1 mo @ 200 AED = 400 AED unused - 100 AED fee = 300 AED)
        const usedCost = 200.0;
        const penaltyFee = 100.0;
        final unused = _paidAmount - usedCost;
        return (unused - penaltyFee).clamp(0.0, _paidAmount);

      case RefundPolicyModel.recalculateStandard:
        // Policy C: Paid 510 AED (15% 3-mo discount). 1-Mo Full Rate = 250 AED -> Refund = 260 AED
        const fullOneMonthRate = 250.0;
        return (_discountedPaid - fullOneMonthRate).clamp(0.0, _discountedPaid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'اختيار سياسة الإلغاء واحتساب الاسترداد' : 'Select Refund & Early Exit Policy',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      isAr ? 'اختبار النماذج المالية والخصومات (Booking $_shelvesCount Shelves)' : 'Financial Models Breakdown ($_shelvesCount Shelves @ 100 AED/mo)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          RadioGroup<RefundPolicyModel>(
            groupValue: _selectedModel,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedModel = val);
              }
            },
            child: Column(
              children: [
                // ── POLICY A CARD ────────────────────────────────────────────────
                _buildPolicyOptionTile(
                  model: RefundPolicyModel.strictNonRefundable,
                  badgeTitle: isAr ? 'نموذج أ: غير قابل للاسترداد (Standard SaaS)' : 'Model A: Strict Non-Refundable (Standard SaaS)',
                  badgeColor: Colors.grey.shade700,
                  financialImpact: isAr ? 'يتم مصادرة المدة المتبقية. لا يتم إصدار أي استرداد مالي.' : 'Remaining months are forfeited. No refund issued.',
                  exampleBreakdown: isAr ? 'المبلغ المدفوع: 600 د.إ • الاسترداد: 0.00 د.إ' : 'Total Paid: 600 AED • Refund: 0.00 AED',
                  calculatedRefundStr: '0.00 AED',
                ),

                const SizedBox(height: 12),

                // ── POLICY B CARD ────────────────────────────────────────────────
                _buildPolicyOptionTile(
                  model: RefundPolicyModel.partialWithFee,
                  badgeTitle: isAr ? '⭐ نموذج ب: استرداد جزئي مع غرامة خروج (موصى به)' : '⭐ Model B: Partial Refund with Exit Fee (Recommended)',
                  badgeColor: Colors.blue.shade800,
                  financialImpact: isAr ? 'استرداد الأشهر غير المستعملة خصماً منها رسوم الغرامة (100 د.إ).' : 'Unused months refunded minus a cancellation penalty (100 AED fee).',
                  exampleBreakdown: isAr ? 'المدفوع: 600 د.إ • المستخدم: 200 د.إ • الغرامة: 100 د.إ' : 'Paid: 600 AED • Used: 200 AED • Exit Fee: 100 AED',
                  calculatedRefundStr: '300.00 AED',
                ),

                const SizedBox(height: 12),

                // ── POLICY C CARD ────────────────────────────────────────────────
                _buildPolicyOptionTile(
                  model: RefundPolicyModel.recalculateStandard,
                  badgeTitle: isAr ? 'نموذج ج: إعادة الاحتساب بالسعر الشهري القياسي' : 'Model C: Recalculate to Standard Monthly Rate',
                  badgeColor: Colors.purple.shade800,
                  financialImpact: isAr ? 'إلغاء خصم الباقة متعددة الأشهُر واحتساب الشهر المستعمل بالسعر الكامل (250 د.إ).' : 'Discounted multi-month rates revert to standard monthly pricing for used months.',
                  exampleBreakdown: isAr ? 'المدفوع بخصم 15%: 510 د.إ • سعر الشهر الكامل: 250 د.إ' : 'Paid (15% 3-mo discount): 510 AED • 1-Mo Full Rate: 250 AED',
                  calculatedRefundStr: '260.00 AED',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FINANCIAL SUMMARY CALLOUT BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الرصيد المالي المسترد للمحفظة:' : 'Refund Credit to Merchant Wallet:',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AED ${_calculatedRefund.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: Text(
                    isAr ? 'تأكيد الإلغاء 💰' : 'Confirm Exit 💰',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => widget.onConfirmCancel(_selectedModel, _calculatedRefund),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyOptionTile({
    required RefundPolicyModel model,
    required String badgeTitle,
    required Color badgeColor,
    required String financialImpact,
    required String exampleBreakdown,
    required String calculatedRefundStr,
  }) {
    final bool isSelected = _selectedModel == model;

    return InkWell(
      onTap: () => setState(() => _selectedModel = model),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<RefundPolicyModel>(
              value: model,
              activeColor: badgeColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: badgeColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    financialImpact,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exampleBreakdown,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Refund', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  calculatedRefundStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: calculatedRefundStr == '0.00 AED' ? Colors.grey : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
