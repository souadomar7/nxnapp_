import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() { _notifications = []; _isLoading = false; });
        return;
      }
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) _notifications[idx]['is_read'] = true;
      });
    } catch (_) {}
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'order_placed': return Icons.shopping_bag_outlined;
      case 'order_confirmed': return Icons.check_circle_outline;
      case 'order_preparing': return Icons.inventory_2_outlined;
      case 'shipped': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.done_all_rounded;
      case 'inbound_received': return Icons.move_to_inbox_outlined;
      case 'payment': return Icons.payment_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'order_placed': return AppColors.bluePrimary;
      case 'order_confirmed': return Colors.green;
      case 'order_preparing': return Colors.purple;
      case 'shipped': return Colors.orange;
      case 'delivered': return Colors.teal;
      case 'inbound_received': return Colors.indigo;
      case 'payment': return Colors.amber.shade800;
      default: return Colors.grey;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? '🔔 الإشعارات' : '🔔 Notifications',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                isAr ? 'قراءة الكل' : 'Mark all read',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد إشعارات بعد' : 'No notifications yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = _notifications[i];
                      final isUnread = n['is_read'] == false;
                      final type = n['type'] as String?;
                      return GestureDetector(
                        onTap: () => _markRead(n['id']),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUnread ? AppColors.bluePrimary.withValues(alpha: 0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUnread ? AppColors.bluePrimary.withValues(alpha: 0.2) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _colorForType(type).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_iconForType(type), color: _colorForType(type), size: 22),
                                  ),
                                  if (isUnread)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.bluePrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['body'] ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(n['created_at']),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
