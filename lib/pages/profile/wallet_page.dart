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
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Top Up (Coming Soon)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                  ),
                )
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
