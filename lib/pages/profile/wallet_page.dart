import 'package:flutter/material.dart';
import '../../theme.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final transactions = [
      {'title': 'Subscription Renewal - Al Karama', 'date': '2025-12-15', 'amount': '-500 AED', 'type': 'debit'},
      {'title': 'Delivery Fee - Order #1234', 'date': '2025-12-10', 'amount': '-45 AED', 'type': 'debit'},
      {'title': 'Refund - Order #1111', 'date': '2025-12-05', 'amount': '+100 AED', 'type': 'credit'},
      {'title': 'Subscription - Abu Dhabi', 'date': '2025-11-20', 'amount': '-1200 AED', 'type': 'debit'},
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Wallet & Payouts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('AED 0.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
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
                                      content: Text('IBAN Payout requested! 14-day clearance countdown initiated.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Submit Payout'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Request IBAN Payout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(alignment: Alignment.centerLeft, child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx['type'] == 'credit';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit ? Colors.green[50] : Colors.red[50],
                    child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                  ),
                  title: Text(tx['title']!),
                  subtitle: Text(tx['date']!),
                  trailing: Text(tx['amount']!, style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.black)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
