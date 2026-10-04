import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/history_models.dart';
import '../request_delivery_page.dart';
import '../booking_page.dart';
import 'wallet_page.dart';

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

    if (mounted) {
      setState(() {
        _subscriptions = list;
        _isLoading = false;
      });
    }
  }

  void _openCancellationModal(int index, bool isAr) {
    final sub = _subscriptions[index];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CancellationModal(
        subscription: sub,
        isAr: isAr,
        onConfirmCancel: (refundAmount) async {
          Navigator.pop(ctx);
          await _processCancellation(index, sub['id'].toString(), refundAmount, isAr);
        },
      ),
    );
  }

  Future<void> _processCancellation(
    int index,
    String subId,
    double refundAmount,
    bool isAr,
  ) async {
    setState(() {
      _subscriptions[index]['auto_renew'] = false;
      _subscriptions[index]['cancellation_pending'] = true;
      _subscriptions[index]['refund_amount'] = refundAmount;
    });

    final res = await _marketplaceService.requestSubscriptionCancellation(
      subscriptionId: subId,
      cancellationReason: 'Cancelled by merchant before renewal',
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
    await _marketplaceService.addActivity(
      DashboardActivity(
        id: 'ACT-SUB-CANCEL-${DateTime.now().millisecondsSinceEpoch}',
        title: isAr ? 'طلب إلغاء الاشتراك' : 'Subscription Cancellation Requested',
        subtitle: isAr
            ? (refundAmount > 0
                ? 'تم تسجيل طلب الإلغاء. استرداد متوقع: $refundAmount د.إ للأشهر المستقبلية المدفوعة مسبقاً.'
                : 'تم إيقاف التجديد التلقائي للشهر القادم. الشهر الحالي غير قابل للاسترداد.')
            : (refundAmount > 0
                ? 'Cancellation requested. Estimated partial refund: AED $refundAmount for prepaid future months.'
                : 'Auto-renewal stopped for next month. Current month is non-refundable.'),
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
                  final rawName = sub['warehouse_name'] ?? sub['warehouses']?['name'] ?? 'Dubai Central Hub';
                  final rawNameAr = sub['warehouse_name_ar'] ?? sub['warehouses']?['name_ar'];
                  final warehouseName = isAr
                      ? (rawNameAr != null && rawNameAr.toString().isNotEmpty
                          ? rawNameAr.toString()
                          : (rawName.toString().contains('Dubai') ? 'مستودع دبي المركزي' : (rawName.toString().contains('Sharjah') ? 'مستودع الشارقة الإقليمي' : 'مستودع لوجستي')))
                      : rawName.toString();
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
                                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                                  onPressed: () => _openCancellationModal(index, isAr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: Text(isAr ? 'إلغاء الاشتراك' : 'Cancel Subscription', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
// CLIENT-ALIGNED CANCELLATION & REFUND MODAL
// ─────────────────────────────────────────────────────────────────────────────

class _CancellationModal extends StatefulWidget {
  final Map<String, dynamic> subscription;
  final bool isAr;
  final Function(double refundAmount) onConfirmCancel;

  const _CancellationModal({
    required this.subscription,
    required this.isAr,
    required this.onConfirmCancel,
  });

  @override
  State<_CancellationModal> createState() => _CancellationModalState();
}

class _CancellationModalState extends State<_CancellationModal> {
  double get _paidAmount => (widget.subscription['total_paid'] as num?)?.toDouble() ?? 200.0;
  int get _durationMonths => (widget.subscription['duration_months'] as num?)?.toInt() ?? 1;
  int get _shelvesCount => (widget.subscription['shelves_count'] as num?)?.toInt() ?? 1;
  double get _monthlyFee => (widget.subscription['monthly_fee'] as num?)?.toDouble() ?? (_shelvesCount * 100.0);

  // Client Rule: Current month is never refunded.
  // If cancelled before next billing date, next month is not charged.
  // If prepaid in advance for future months, partial refund applies to unused future months.
  double get _calculatedRefund {
    if (_durationMonths > 1) {
      // 1 month has been used / active
      final unusedMonths = _durationMonths - 1;
      return (unusedMonths * _monthlyFee).clamp(0.0, _paidAmount);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final refund = _calculatedRefund;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_presentation_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'سياسة وإجراءات إلغاء الاشتراك' : 'Subscription Cancellation Terms',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      isAr
                          ? 'إلغاء حجز $_shelvesCount أرفف • ${_monthlyFee.toStringAsFixed(0)} د.إ / شهرياً'
                          : '$_shelvesCount Shelves • AED ${_monthlyFee.toStringAsFixed(0)} / mo',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Policy Terms Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicyRule(
                  icon: Icons.block_rounded,
                  color: Colors.red.shade700,
                  title: isAr ? 'الشهر الحالي غير قابل للاسترداد' : 'Current Month Non-Refundable',
                  subtitle: isAr
                      ? 'رسوم إيجار الأرفف للشهر الحالي غير قابلة للاسترداد وفقاً لسياسة المستودع بعد بدء الفترة التشغيلية.'
                      : 'Shelf fees for the current month are non-refundable once the billing period has commenced.',
                ),
                const Divider(height: 20),
                _buildPolicyRule(
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                  title: isAr ? 'إيقاف التجديد للشهر القادم' : 'No Charge for Next Month',
                  subtitle: isAr
                      ? 'عند الإلغاء قبل تاريخ الفاتورة القادمة، لن يتم تجديد الاشتراك أو خصم أي مبالغ للشهر التالي.'
                      : 'Cancelling prior to the next billing date ensures the upcoming month will not be renewed or charged.',
                ),
                if (_durationMonths > 1) ...[
                  const Divider(height: 20),
                  _buildPolicyRule(
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.blue.shade700,
                    title: isAr ? 'استرداد جزئي للأشهر المدفوعة مسبقاً' : 'Prepaid Future Months Partial Refund',
                    subtitle: isAr
                        ? 'نظراً لدفع باقة لعدة أشهر مسبقاً، يحق لك استرداد جزئي للأشهر المستقبلية غير المستعملة (${_durationMonths - 1} أشهر متبقية).'
                        : 'Because future months were prepaid, unused future billing cycles qualify for partial refund (${_durationMonths - 1} months remaining).',
                  ),
                ],
                const Divider(height: 20),
                _buildPolicyRule(
                  icon: Icons.local_shipping_outlined,
                  color: Colors.orange.shade800,
                  title: isAr ? 'جدولة سحب البضائع' : 'Schedule Inventory Outbound',
                  subtitle: isAr
                      ? 'يرجى التنسيق لسحب بضائعك من المستودع قبل تاريخ انتهاء فترة الحجز الحالية.'
                      : 'Please arrange outbound pickup to clear your warehouse shelves before the current cycle ends.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Financial Summary Card
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
                        isAr ? 'الاسترداد المالي المتوقع للمحفظة:' : 'Estimated Wallet Refund:',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        refund > 0 ? 'AED ${refund.toStringAsFixed(2)}' : (isAr ? '0.00 د.إ (لا يوجد رصيد متبقٍ)' : 'AED 0.00 (No prepaid excess)'),
                        style: TextStyle(
                          color: refund > 0 ? Colors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: Text(
                    isAr ? 'تأكيد الإلغاء' : 'Confirm Exit',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => widget.onConfirmCancel(refund),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyRule({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
