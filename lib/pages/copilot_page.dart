import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import 'payment_page.dart';
import '../core/services/chatbot_engine.dart';

enum ChatCardType { none, inventoryAlert, bookingQuote, gatePass, deliveryTracker }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatCardType cardType;
  final dynamic cardData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.cardType = ChatCardType.none,
    this.cardData,
  });
}

class CopilotPage extends StatefulWidget {
  const CopilotPage({super.key});

  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;
  final ChatbotEngine _chatbotEngine = ChatbotEngine();

  final List<String> _suggestions = [
    "📊 Check stock alerts",
    "🏢 Rent 3 shelves in Dubai",
    "🎫 Generate a Gate Pass",
    "🚚 Track shipment to Sharjah",
  ];

  @override
  void initState() {
    super.initState();
    // Add initial greetings
    _messages.add(
      ChatMessage(
        text: "Hello! I am your **NXN Copilot**. 🤖✨\n\nI can help you manage your micro-warehouses, check live inventory, request deliveries, or draft shelf bookings using simple chat.\n\nWhat would you like to do today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    // Trigger AI response after delay
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _generateAiResponse(text);
    });
  }

  Future<void> _generateAiResponse(String userQuery) async {
    String text = "";
    ChatCardType cardType = ChatCardType.none;
    dynamic cardData;

    final query = userQuery.toLowerCase();

    if (query.contains("stock") || query.contains("inventory") || query.contains("alert") || query.contains("📊")) {
      text = "Checking stock levels across all branches... 📊\n\nI have found **2 active stock alerts** in your inventory. One is critically low, and another is completely out of stock. Here is the summary:";
      cardType = ChatCardType.inventoryAlert;
    } else if (query.contains("rent") || query.contains("shelf") || query.contains("booking") || query.contains("🏢")) {
      text = "Perfect! Checking available shelf space in **Dubai (Al Quoz)**... 🏢\n\nI have drafted a flexible rental quote for you. You can review the details below and proceed to pay securely with Fintx or Apple Pay:";
      cardType = ChatCardType.bookingQuote;
      cardData = {
        'location': 'Dubai (Al Quoz)',
        'shelves': 3,
        'duration': 2, // months
        'price': 600.0, // AED
      };
    } else if (query.contains("gate") || query.contains("pass") || query.contains("entry") || query.contains("🎫")) {
      text = "Generating entry pass... 🎫\n\nI've generated a secure **Gate Pass QR Code** for your upcoming drop-off at the **Al Ain Branch**. Show this at the warehouse gate for seamless access:";
      cardType = ChatCardType.gatePass;
      cardData = {
        'passId': 'GP-7721',
        'location': 'Al Ain Branch',
        'reason': 'Inbound Delivery',
        'validUntil': 'Valid until: Tomorrow, 6:00 PM',
      };
    } else if (query.contains("track") || query.contains("shipment") || query.contains("sharjah") || query.contains("🚚")) {
      text = "Retrieving shipment status from Wasel Logistics... 🚚\n\nHere is the real-time tracking timeline for your outbound order of **12 Honey Jars** destined for Sharjah:";
      cardType = ChatCardType.deliveryTracker;
      cardData = {
        'orderId': 'DL-3349',
        'recipient': 'Sarah Ahmad',
        'address': 'Rolla, Sharjah',
        'status': 'In Transit via Wasel',
      };
    } else {
      // Use the advanced ChatbotEngine for everything else (Deterministic Matching + LLM Fallback)
      final engineResponse = await _chatbotEngine.processMessage(userQuery);
      text = engineResponse.text;
    }

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          cardType: cardType,
          cardData: cardData,
        ),
      );
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicatorBubble();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildSuggestionsBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.bluePrimary, size: 24),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
                const Text(
                  "NXN Copilot",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Online Assistant",
                  style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () {
            setState(() {
              _messages.clear();
              _messages.add(
                ChatMessage(
                  text: "Hello! I am your **NXN Copilot**. 🤖✨\n\nI can help you manage your micro-warehouses, check live inventory, request deliveries, or draft shelf bookings using simple chat.\n\nWhat would you like to do today?",
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(suggestion),
              labelStyle: const TextStyle(
                color: AppColors.bluePrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              onPressed: () => _handleSendMessage(suggestion.substring(2)), // Strip icon
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Type a logistics command...",
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        filled: false,
                      ),
                      onSubmitted: _handleSendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.bluePrimary),
                    onPressed: () => _handleSendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.bluePrimary, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isUser ? AppColors.bluePrimary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (message.cardType != ChatCardType.none) ...[
                    const SizedBox(height: 8),
                    _buildRichCard(message.cardType, message.cardData),
                  ],
                ],
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.blueSecondary.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded, color: AppColors.blueSecondary, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRichCard(ChatCardType type, dynamic data) {
    switch (type) {
      case ChatCardType.inventoryAlert:
        return _buildInventoryAlertCard();
      case ChatCardType.bookingQuote:
        return _buildBookingQuoteCard(data);
      case ChatCardType.gatePass:
        return _buildGatePassCard(data);
      case ChatCardType.deliveryTracker:
        return _buildDeliveryTrackerCard(data);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Inventory Alert Custom Card
  Widget _buildInventoryAlertCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.red.shade50.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              const Text("Active Stock Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          // Alert 1
          const Text("Organic Coffee Beans", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Al Ain Warehouse", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text("5 / 50 bags left", style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.1,
              minHeight: 6,
              color: Colors.orange.shade600,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 16),
          // Alert 2
          const Text("Eco Tea Bags (Mint)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dubai Warehouse", style: TextStyle(fontSize: 11, color: Colors.grey)),
              const Text("0 units left (🚨 OUT)", style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.0,
              minHeight: 6,
              color: Colors.red,
              backgroundColor: Color(0xFFFEE2E2),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_business_rounded, size: 16),
              label: const Text("Schedule Restock", style: TextStyle(fontSize: 12)),
              onPressed: () => _handleSendMessage("Schedule restock for Organic Coffee Beans"),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Booking Quote Custom Card
  Widget _buildBookingQuoteCard(dynamic data) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.store_mall_directory_rounded, color: AppColors.bluePrimary, size: 20),
              SizedBox(width: 8),
              Text("Draft Shelf Quote", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          _buildQuoteRow("Location", data['location']),
          _buildQuoteRow("Shelves Requested", "${data['shelves']} Shelves"),
          _buildQuoteRow("Duration", "${data['duration']} Months"),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("AED ${data['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsPage()),
                );
              },
              child: const Text("Pay with Fintx / Apple Pay", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // 3. Gate Pass Custom Card
  Widget _buildGatePassCard(dynamic data) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text("ENTRY GATE PASS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(data['validUntil'], style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          QrImageView(
            data: "gatepass:${data['passId']}",
            version: QrVersions.auto,
            size: 140,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.bluePrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.bluePrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(data['passId'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Location", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(data['location'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Delivery Tracker Timeline Custom Card
  Widget _buildDeliveryTrackerCard(dynamic data) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("Shipment #${data['orderId']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(data['status'], style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Recipient: ${data['recipient']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Divider(height: 20),
          _buildTrackerStep("Order Picked", "Dubai Warehouse Shelf B-12", true),
          _buildTrackerStep("In Transit", "Dispatched via Wasel Express", true, isCurrent: true),
          _buildTrackerStep("Out for Delivery", "Sharjah Regional hub", false),
          _buildTrackerStep("Delivered", "Handover to customer", false, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTrackerStep(String title, String subtitle, bool isCompleted, {bool isCurrent = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isCompleted ? (isCurrent ? AppColors.bluePrimary : Colors.green) : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isCurrent ? [BoxShadow(color: AppColors.bluePrimary.withValues(alpha: 0.3), blurRadius: 6)] : null,
              ),
              child: isCompleted && !isCurrent
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isCurrent ? AppColors.textPrimary : (isCompleted ? AppColors.textPrimary.withValues(alpha: 0.8) : Colors.grey),
                ),
              ),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.bluePrimary, size: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _TypingDot(delay: 0),
                  SizedBox(width: 4),
                  _TypingDot(delay: 150),
                  SizedBox(width: 4),
                  _TypingDot(delay: 300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
