import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/loading_state.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _repository = WalletRepository();
  bool _isLoading = true;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _repository.getBalance();
      final txs = await _repository.getTransactions();
      if (mounted) {
        setState(() {
          _balance = balance;
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Wallet & Payouts',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading ledger balance...')
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Text('Available Balance',
                              style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            'AED ${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showPayoutDialog,
                                icon: const Icon(Icons.account_balance_wallet_outlined),
                                label: const Text('Request IBAN Payout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bluePrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: Colors.orange.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Settlement Policy: 14-day clearance hold applies before funds transfer to UAE IBAN.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Transactions History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                  ),
                  _transactions.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyState(
                            message: 'No wallet transactions recorded yet.',
                            icon: Icons.receipt_long_outlined,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx = _transactions[index];
                              final isCredit = tx['direction'] == 'credit';
                              final amount = (tx['amount_aed'] as num?)?.toDouble() ?? 0.0;
                              final type = tx['type']?.toString().toUpperCase() ?? 'TX';
                              final date = tx['created_at'] != null
                                  ? tx['created_at'].toString().split('T').first
                                  : 'Recent';

                              return Material(
                                color: Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                    child: Icon(
                                      isCredit
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: isCredit
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    tx['notes'] ?? type,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    date,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '${isCredit ? "+" : "-"}AED ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _transactions.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  void _showPayoutDialog() {
    final ibanCtrl = TextEditingController(text: 'AE070331234567890123456');
    final bankCtrl = TextEditingController(text: 'Emirates NBD');
    final amountCtrl = TextEditingController(text: (_balance >= 150.0 ? _balance.clamp(150.0, 5000.0) : 150.0).toStringAsFixed(0));
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: AppColors.bluePrimary, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Request IBAN Payout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Available to Withdraw:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          'AED ${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ibanCtrl,
                    decoration: InputDecoration(
                      labelText: 'UAE IBAN *',
                      hintText: 'AE000000000000000000000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bankCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bank Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (AED) *',
                      helperText: 'Min withdrawal: AED 150.00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final entered = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  final iban = ibanCtrl.text.trim();

                  if (iban.isEmpty || !iban.toUpperCase().startsWith('AE')) {
                    setDialogState(() => errorText = 'Please enter a valid UAE IBAN starting with AE');
                    return;
                  }
                  if (entered < 150.0) {
                    setDialogState(() => errorText = 'Minimum withdrawal amount is AED 150.00');
                    return;
                  }
                  if (entered > _balance) {
                    setDialogState(() => errorText = 'Amount exceeds your available balance (AED ${_balance.toStringAsFixed(2)})');
                    return;
                  }

                  Navigator.pop(ctx);

                  setState(() {
                    _balance -= entered;
                    _transactions.insert(0, {
                      'id': 'payout-${DateTime.now().millisecondsSinceEpoch}',
                      'direction': 'debit',
                      'amount_aed': entered,
                      'type': 'payout_hold',
                      'notes': 'IBAN Payout (${bankCtrl.text.trim()})',
                      'created_at': DateTime.now().toIso8601String(),
                    });
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Withdrawal request of AED ${entered.toStringAsFixed(2)} submitted successfully!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Payout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
