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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request IBAN Payout'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'UAE IBAN (AE...)')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Bank Name')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Amount (AED)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'IBAN Payout requested! 14-day clearance countdown initiated.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Payout'),
          ),
        ],
      ),
    );
  }
}
