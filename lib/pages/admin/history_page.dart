import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Activity Logs'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _logItem('Received Truck #DXB-9988', '10:30 AM', Colors.green),
          _logItem('Put-Away Item #8818 to A-10', '10:45 AM', Colors.blue),
          _logItem('System Alert: Low Storage Space', '11:00 AM', Colors.red),
          _logItem('Dispatched Order #OUT-9911', '12:15 PM', Colors.orange),
          _logItem('Staff Login: User #004', '08:00 AM', Colors.grey),
        ],
      ),
    );
  }

  Widget _logItem(String title, String time, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(Icons.circle, size: 18, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
