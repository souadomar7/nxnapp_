import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../providers/locale_provider.dart';
import 'checkout_page.dart';
import '../services/payment_service.dart';
import '../models/invoice.dart';
import '../services/ai_agent_service.dart';
import 'create_shipment_page.dart';
import 'marketplace/add_product_page.dart';
import 'marketplace/seller_orders_page.dart';
import 'booking_page.dart';
import 'settings/kyc_page.dart';
import 'profile/wallet_page.dart';
import 'smart_inventory_stage.dart';
import 'operations/tracking_page.dart';
import 'registration_page.dart';
import 'marketplace/seller_products_page.dart';
import 'marketplace/home_seller_marketplace_hub.dart';
import 'operations/outbound_order_creation_page.dart';
import 'operations/inbound_intake_inspection_page.dart';
enum ChatCardType { none, inventoryAlert, bookingQuote, gatePass, deliveryTracker, damagedQuarantineAlert }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatCardType cardType;
  final dynamic cardData;
  final AgentAction? agentAction;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.cardType = ChatCardType.none,
    this.cardData,
    this.agentAction,
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
  final AiAgentService _agentService = AiAgentService();
  String? _lastLanguageCode;

  @override
  void initState() {
    super.initState();
  }

  String _getInitialGreeting(bool isAr) {
    if (isAr) {
      return "👋 أهلاً بك في **المساعد الذكي لـ NXN**! 🤖✨\n\nأنا مستشارك الذكي لإدارة المستودعات والخدمات اللوجستية على مدار الساعة.\n\nإليك ما يمكنني مساعدتك به اليوم:\n\n📦 **المساحات التخزينية والأرفف**\n• حساب فوري للتكاليف وتوصيات المساحة المناسبة\n\n🚚 **الشحنات والتوصيل**\n• خيارات Drop-off و Pick-up وتصاريح الدخول\n\n🛍️ **السوق التجاري والمنتجات**\n• إضافة وتعديل المنتجات والأسعار مباشرة\n\n📜 **الامتثال والتراخيص**\n• ضريبة القيمة المضافة (5%) وتوثيق KYC\n\n💰 **سحوبات التاجر**\n• فترات الحجز (14 يوماً) وإجراءات السحب\n\nاختر من الأسئلة السريعة أدناه أو اكتب سؤالك مباشرة! 👇";
    } else {
      return "👋 Welcome to **NXN AI Agent**! 🤖✨\n\nI am your 24/7 intelligent logistics & fulfillment advisor.\n\nHere is how I can assist you today:\n\n📦 **Micro-Warehousing & Space Subscriptions**\n• Instant shelf rental quotes & capacity recommendations\n\n🚚 **Inbound & Outbound Logistics**\n• Drop-off vs. Pick-up choices & Gate Pass (STO) scheduling\n\n🛍️ **Marketplace & Products**\n• Adding products & 100% merchant price control\n\n📜 **Compliance & Trade License**\n• UAE FTA Tax rules (5% VAT) & KYC verification\n\n💰 **Merchant Financials**\n• 14-day seller hold periods & payout processing\n\nTap any prompt below or type your question! 👇";
    }
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

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _generateAiResponse(text);
    });
  }

  Future<void> _generateAiResponse(String userQuery) async {
    final agentResponse = await _agentService.sendMessage(userQuery);

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: agentResponse.text,
          isUser: false,
          timestamp: DateTime.now(),
          agentAction: agentResponse.action,
        ),
      );
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isArCurrent = localeProvider.locale.languageCode == 'ar';
    final currentLang = isArCurrent ? 'ar' : 'en';

    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          text: _getInitialGreeting(isArCurrent),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _lastLanguageCode = currentLang;
    } else if (_lastLanguageCode != currentLang) {
      _lastLanguageCode = currentLang;
      if (_messages.isNotEmpty && !_messages[0].isUser) {
        _messages[0] = ChatMessage(
          text: _getInitialGreeting(isArCurrent),
          isUser: false,
          timestamp: _messages[0].timestamp,
          cardType: _messages[0].cardType,
          cardData: _messages[0].cardData,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isArCurrent),
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

  PreferredSizeWidget _buildAppBar(bool isArCurrent) {
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
                Text(
                  isArCurrent ? "المساعد الذكي NXN" : "NXN AI Agent",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isArCurrent ? "المساعد اللوجستي المباشر" : "Online Assistant",
                  style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            final isAr = localeProvider.locale.languageCode == 'ar';
            return InkWell(
              onTap: () {
                localeProvider.toggleLocale();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.bluePrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isAr ? 'EN' : 'العربية',
                      style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            setState(() {
              _messages.clear();
              _messages.add(
                ChatMessage(
                  text: _getInitialGreeting(isAr),
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSuggestionsBar() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final suggestions = isAr
        ? [
            {"label": "❓ كيف يتم حساب أسعار إيجار الأرفف؟", "query": "كيف يتم حساب أسعار إيجار الأرفف والاشتراك؟"},
            {"label": "🚛 ما الفرق بين Drop-off و Pick-up؟", "query": "ما الفرق بين تسليم البضائع Drop-off واستلامها Pick-up؟"},
            {"label": "📜 ما المستندات المطلوبة للتحقق (KYC)؟", "query": "ما هي المستندات والبيانات المطلوبة للتحقق (KYC)؟"},
            {"label": "💰 كيف تعمل سحوبات الأرباح للتاجر (14 يوماً)؟", "query": "كيف تعمل سحوبات الأرباح للتاجر (14 يوماً) للحساب البنكي؟"},
          ]
        : [
            {"label": "❓ How is shelf rental pricing calculated?", "query": "How is shelf rental pricing and subscription calculated?"},
            {"label": "🚛 Drop-off vs Pick-up differences?", "query": "What is the difference between Drop-off and Pick-up?"},
            {"label": "📜 What documents are required for KYC?", "query": "What documents are required for KYC verification?"},
            {"label": "💰 How do 14-day seller payouts work?", "query": "How do 14-day seller IBAN payouts work?"},
          ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(suggestion["label"]!),
              labelStyle: const TextStyle(
                color: AppColors.bluePrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              onPressed: () => _handleSendMessage(suggestion["query"]!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
          // Voice Note Taker Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showVoiceNoteModal,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Color(0xFFFF5252),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                      decoration: InputDecoration(
                        hintText: isAr ? "تحدث أو اكتب أمرك اللوجستي..." : "Speak or type logistics command...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showVoiceNoteModal() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceNoteSheet(
        isAr: isAr,
        onTranscriptSubmitted: (text) {
          Navigator.pop(ctx);
          _handleSendMessage(text);
        },
      ),
    );
  }

  Widget _buildFormattedText(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
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
                    child: _buildFormattedText(
                      message.text,
                      TextStyle(
                        fontSize: 14,
                        color: message.isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (message.cardType != ChatCardType.none) ...[
                    const SizedBox(height: 8),
                    _buildRichCard(message.cardType, message.cardData),
                  ],
                  if (message.agentAction != null) ...[
                    if (message.agentAction!.type == 'direct_checkout')
                      _buildDirectCheckoutCard(message.agentAction!.payload)
                    else if (message.agentAction!.type == 'direct_gate_pass')
                      _buildGatePassCard(message.agentAction!.payload)
                    else ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (ctx) {
                          final isAr = Localizations.localeOf(context).languageCode == 'ar';
                          final actionType = message.agentAction!.type;
                          final payload = message.agentAction!.payload;
                          String btnText = isAr ? 'تنفيذ الإجراء' : 'Take Action';
                          Widget page = Container();

                          if (actionType == 'direct_shipment' || actionType == 'create_shipment') {
                            btnText = isAr ? 'تأكيد طلب التوريد والشحن 🚚' : 'Confirm Inbound Shipment 🚚';
                            page = CreateShipmentPage(
                              initialIsDropOff: payload['is_drop_off'] ?? true,
                              initialItemCount: payload['item_count'],
                              initialWarehouseId: payload['warehouse_id'],
                              initialPickupLocation: payload['pickup_location'],
                              initialGoodsType: payload['goods_type'],
                            );
                          } else if (actionType == 'direct_add_product' || actionType == 'add_product') {
                            btnText = isAr ? 'إكمال ونشر المنتج بالسوق 🛍️' : 'Complete & Publish Listing 🛍️';
                            page = AddProductPage(
                              initialName: payload['name'],
                              initialPrice: (payload['price'] as num?)?.toDouble(),
                              initialQty: payload['quantity'],
                              initialCategory: payload['category'],
                            );
                          } else if (actionType == 'direct_edit_price' || actionType == 'edit_price' || actionType == 'manage_pricing') {
                            btnText = isAr ? 'تأكيد وتطبيق السعر الجديد 🏷️' : 'Confirm & Apply Price 🏷️';
                            page = const SellerProductsPage();
                          } else if (actionType == 'direct_track_order' || actionType == 'track_order') {
                            btnText = isAr ? 'فتح خريطة التتبع المباشرة 📍' : 'Open Live Map Tracking 📍';
                            page = const TrackingPage();
                          } else if (actionType == 'direct_wallet_payout' || actionType == 'open_wallet') {
                            btnText = isAr ? 'تأكيد السحب البنكي (IBAN) 🏦' : 'Confirm Bank Withdrawal (IBAN) 🏦';
                            page = const WalletPage();
                          } else if (actionType == 'open_booking') {
                            btnText = isAr ? 'احجز مساحة الآن' : 'Book Space Now';
                            page = const BookingPage();
                          } else if (actionType == 'view_orders') {
                            btnText = isAr ? 'عرض الطلبات' : 'View Orders';
                            page = const SellerOrdersPage();
                          } else if (actionType == 'view_inventory') {
                            btnText = isAr ? 'لوحة المخزون' : 'View Inventory';
                            page = const SmartInventoryStageEN();
                          } else if (actionType == 'open_kyc') {
                            btnText = isAr ? 'التحقق من الهوية والترخيص' : 'Verify KYC Documents';
                            page = const KYCPage();
                          } else if (actionType == 'open_home_seller_hub' || actionType == 'sme_marketplace') {
                            btnText = isAr ? 'فتح منصة الأسر والشركات 🛍️' : 'Open Home Seller Hub 🛍️';
                            page = const HomeSellerMarketplaceHubPage();
                          } else if (actionType == 'create_outbound_order' || actionType == 'outbound_dispatch') {
                            btnText = isAr ? 'إنشاء أمر شحن وتوزيع 🚀' : 'Create Outbound Order 🚀';
                            page = const OutboundOrderCreationPage();
                          } else if (actionType == 'open_intake_inspection' || actionType == 'intake_inspection') {
                            btnText = isAr ? 'فحص واستلام البضائع 📦' : 'Inspect & Receive Intake 📦';
                            page = const InboundIntakeInspectionPage();
                          } else if (actionType == 'start_uae_pass') {
                            btnText = isAr ? 'التسجيل عبر الهوية الرقمية' : 'Register with UAE PASS';
                            page = const RegistrationPage();
                          }
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bluePrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(btnText),
                          );
                        }
                      ),
                    ],
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

  Widget _buildDirectCheckoutCard(Map<String, dynamic> payload) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final warehouseName = isAr
        ? (payload['warehouse_name_ar'] ?? payload['warehouse_name'] ?? 'مستودع دبي المركزي')
        : (payload['warehouse_name'] ?? 'Dubai Central Warehouse');
    final int shelves = (payload['shelves_count'] as num?)?.toInt() ?? 39;
    final int months = (payload['duration_months'] as num?)?.toInt() ?? 5;
    final double amount = (payload['amount'] as num?)?.toDouble() ?? (shelves * 100.0 * months);
    final double vat = (payload['vat'] as num?)?.toDouble() ?? (amount * 0.05);
    final double total = (payload['total'] as num?)?.toDouble() ?? (amount + vat);
    final String invNum = payload['invoice_number'] ?? 'INV-RENT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warehouse_rounded, color: AppColors.bluePrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? "⚡ طلب حجز جاهز للدفع" : "⚡ Instant Booking Ready",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.bluePrimary),
                    ),
                    Text(
                      warehouseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  isAr ? "حساب فوري" : "Instant Quote",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          // Specs Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCheckoutSpecItem(
                  icon: Icons.shelves,
                  label: isAr ? "الأرفف" : "Shelves",
                  val: "$shelves ${isAr ? 'رف' : 'Units'}",
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildCheckoutSpecItem(
                  icon: Icons.calendar_month_rounded,
                  label: isAr ? "المدة" : "Duration",
                  val: "$months ${isAr ? 'شهور' : 'Mos'}",
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildCheckoutSpecItem(
                  icon: Icons.fitness_center_rounded,
                  label: isAr ? "الحمولة" : "Max Load",
                  val: "${(shelves * 0.5).toStringAsFixed(1)} ${isAr ? 'طن' : 'Tons'}",
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cost Rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? "الإيجار الأساسي ($shelves رف × $months شهور):" : "Base Rental ($shelves shelves × $months mos):",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                "AED ${amount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? "ضريبة القيمة المضافة (5% VAT):" : "UAE VAT (5%):",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                "AED ${vat.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? "الإجمالي المستحق للدفع:" : "Total Payable:",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                "AED ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final invoice = Invoice(
                  id: invNum,
                  number: invNum,
                  warehouseName: payload['warehouse_name'] ?? 'Dubai Central Warehouse',
                  warehouseNameAr: payload['warehouse_name_ar'] ?? 'مستودع دبي المركزي',
                  date: DateTime.now(),
                  amount: amount,
                  vat: vat,
                  workerFee: (payload['worker_fee'] as num?)?.toDouble() ?? 0.0,
                  type: InvoiceType.rental,
                  metaData: {
                    'shelves': shelves,
                    'months': months,
                    'warehouse_id': payload['warehouse_id'] ?? 'dxb',
                    'source': 'ai_voice_direct_booking',
                  },
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CheckoutPage(invoice: invoice)),
                );
              },
              icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
              label: Text(
                isAr
                    ? "انتقل للدفع الآن (${total.toStringAsFixed(2)} درهم) 💳"
                    : "Proceed to Payment (AED ${total.toStringAsFixed(2)}) 💳",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSpecItem({required IconData icon, required String label, required String val}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.bluePrimary),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
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
      case ChatCardType.damagedQuarantineAlert:
        return _buildDamagedQuarantineAlertCard(data);
      default:
        return const SizedBox.shrink();
    }
  }

  // Damaged Quarantine Alert Custom Card
  Widget _buildDamagedQuarantineAlertCard(dynamic data) {
    final Map<String, dynamic> info = data is Map<String, dynamic>
        ? data
        : {
            'hub': 'DXB Hub (Bay 3)',
            'sku': 'SKU-DXB-002',
            'product_name': 'Arabian Coffee Blend',
            'damaged_qty': 2,
            'reason': 'Packaging damage during hub forklift relocation',
            'compensation': 70.0,
          };

    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.amber.shade50.withValues(alpha: 0.6), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "⚠️ Quarantine Alert (${info['hub']})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F)),
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),
          Text(
            "${info['damaged_qty']} units of ${info['sku']} (${info['product_name']}) were moved to quarantine due to: ${info['reason']}.",
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Credit of AED ${(info['compensation'] as num).toStringAsFixed(2)} issued to your Wallet balance.",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text("Select Final Disposition Path:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleSendMessage("Schedule RTV Return for ${info['sku']}"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppColors.bluePrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("🚚 RTV Return", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleSendMessage("Liquidate ${info['sku']} as Refurbished"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: Colors.purple.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("🏷️ Refurbish", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              const Text("Active Stock & Quarantine Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 16, thickness: 1),
          // Quarantine Alert (Edge Case Handling)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("⚠️ Abandoned Cargo Quarantine Alert", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF78350F))),
                SizedBox(height: 2),
                Text("45 SKUs remaining on Shelf B-12 past 14-day grace period. Status: QUARANTINE.", style: TextStyle(fontSize: 10, color: Color(0xFF92400E))),
              ],
            ),
          ),
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
                final double priceVal = (data['price'] is num)
                    ? (data['price'] as num).toDouble()
                    : double.tryParse(data['price'].toString().replaceAll(',', '')) ?? 100.0;
                final double subtotal = priceVal / 1.05;
                final double vat = priceVal - subtotal;
                final invoice = Invoice(
                  id: 'INV-COPILOT-${DateTime.now().millisecondsSinceEpoch}',
                  number: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  warehouseName: data['location']?.toString() ?? 'Dubai Warehouse',
                  date: DateTime.now(),
                  amount: subtotal,
                  vat: vat,
                  paid: false,
                  type: InvoiceType.rental,
                  metaData: {
                    'shelves': data['shelves'],
                    'duration': data['duration'],
                    'source': 'copilot_quote_card',
                  },
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      invoice: invoice,
                      initialMethod: PaymentMethod.fintx,
                    ),
                  ),
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

class _VoiceNoteSheet extends StatefulWidget {
  final bool isAr;
  final ValueChanged<String> onTranscriptSubmitted;

  const _VoiceNoteSheet({
    required this.isAr,
    required this.onTranscriptSubmitted,
  });

  @override
  State<_VoiceNoteSheet> createState() => _VoiceNoteSheetState();
}

class _VoiceNoteSheetState extends State<_VoiceNoteSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _voiceNoteCtrl = TextEditingController();
  int _selectedDialectIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedDialectIndex = widget.isAr ? 0 : 3;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceNoteCtrl.dispose();
    super.dispose();
  }

  void _submitVoiceText(String text) {
    if (text.trim().isEmpty) return;
    widget.onTranscriptSubmitted(text.trim());
  }

  List<String> _getDialectPrompts() {
    switch (_selectedDialectIndex) {
      case 0: // Emirati & Gulf
        return [
          "ابغي ااجر 39 رف في دبي حق 5 شهور ودني للدفع",
          "أريد توريد 25 طرد لمستودع دبي غداً تسليم مباشر (Drop-off)",
          "أضف منتج قهوة كولد برو 250 مل بسعر 18 درهم والكمية 50",
          "عدل سعر العسل الإماراتي إلى 120 درهم",
          "وين وصل طلبي الأخير رقم #ORD-1002",
          "اسحبلي 3500 درهم من المحفظة إلى حسابي البنكي (IBAN)",
          "أصدر تصريح دخول فوري (Gate Pass) لمستودع دبي المركزي",
        ];
      case 1: // Egyptian
        return [
          "عايز ااجر 39 رف في مخزن دبي لمده 5 شهور وادخلني على الدفع",
          "عاوز ابعت 30 كرتونه لمستودع الشارقه دروب اوف",
          "ضيفلي منتج قهوة كولد برو بتمن 18 درهم والكمية 50",
          "غيرلي سعر العسل الإماراتي ل 120 درهم",
          "شوفلي الاوردر بتاعي #ORD-1002 وصل فين دلوقتي",
          "عايز اسحب 3500 درهم على حسابي البنكي",
          "طلعلي تصريح بوابة لمستودع دبي",
        ];
      case 2: // Levantine
        return [
          "بدي استأجر 39 رف بمستودع دبي ل 5 اشهر وخدني للدفع دغري",
          "بدي ابعت 20 كرتونة لمستودع الشارقة تسليم مباشر",
          "ضيف منتج قهوة كولد برو بسعر 18 درهم",
          "عدل سعر العسل ل 120 درهم",
          "وين صار طلبي رقم #ORD-1002",
          "بدي اسحب 3500 درهم عالبنك",
          "اعملي تصريح دخول لمستودع دبي",
        ];
      case 3: // English & Arabizi
      default:
        return [
          "Rent 39 shelves in Dubai warehouse for 5 months and take me to payment",
          "Send 25 boxes to Dubai warehouse tomorrow via Drop-off",
          "baddi a2ajjer 39 raf b dxb la 5 months w khodni 3al payment",
          "Add product Cold Brew Coffee 250ml priced at 18 AED with 50 units",
          "Update price of Emirati Honey to 120 AED",
          "Track my latest order #ORD-1002 live status",
          "Withdraw 3500 AED from my wallet to my UAE bank IBAN",
          "Generate instant Gate Pass (STO) for Dubai Central Warehouse",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickVoiceNotes = _getDialectPrompts();
    final dialectTabs = [
      {"label": "🇦🇪 إماراتي وخليجي", "index": 0},
      {"label": "🇪🇬 مصري", "index": 1},
      {"label": "🇸🇾 شامي", "index": 2},
      {"label": "🌐 English & Arabizi", "index": 3},
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.record_voice_over_rounded, color: AppColors.bluePrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.isAr ? "المسجل والمساعد الصوتي الذكي" : "AI Voice Note Assistant",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.isAr
                  ? "تحدث مباشرة لتنفيذ طلبات التخزين والشحن والدفع الفوري"
                  : "Speak to execute storage quotes, bookings, and instant checkout",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Pulsing Mic Visualizer
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90 * _pulseAnimation.value,
                      height: 90 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15 / _pulseAnimation.value),
                      ),
                    ),
                    Container(
                      width: 75,
                      height: 75,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFFF7675)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FF5252),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isAr ? "جارٍ الاستماع للصوت والترجمة الفورية..." : "Listening to your voice command...",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Dialect / Accent Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dialectTabs.map((tab) {
                  final idx = tab["index"] as int;
                  final label = tab["label"] as String;
                  final isSelected = _selectedDialectIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.bluePrimary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.bluePrimary : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedDialectIndex = idx;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Spoken Command Presets
            Align(
              alignment: widget.isAr ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                widget.isAr ? "أوامر صوتية جاهزة للاختبار بنقرة واحدة:" : "Quick Spoken Commands (1-Tap Test):",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            ...quickVoiceNotes.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _submitVoiceText(prompt),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded, color: AppColors.bluePrimary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "\"$prompt\"",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.bluePrimary, size: 12),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            // Custom spoken input box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voiceNoteCtrl,
                    decoration: InputDecoration(
                      hintText: widget.isAr ? "أو اكتب النص الصوتي هنا..." : "Or type custom spoken text here...",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _submitVoiceText,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _submitVoiceText(_voiceNoteCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.isAr ? "إرسال" : "Send"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

