import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../providers/locale_provider.dart';
import 'payment_page.dart';
import '../core/services/chatbot_engine.dart';

enum ChatCardType { none, inventoryAlert, bookingQuote, gatePass, deliveryTracker, damagedQuarantineAlert }

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
  String? _lastLanguageCode;

  @override
  void initState() {
    super.initState();
  }

  String _getInitialGreeting(bool isAr) {
    if (isAr) {
      return "👋 أهلاً بك في **المساعد الذكي لـ NXN**! 🤖✨\n\nأنا مستشارك الذكي لإدارة المستودعات والخدمات اللوجستية على مدار الساعة.\n\nإليك ما يمكنني مساعدتك به اليوم:\n\n📦 **المساحات التخزينية والأرفف**\n• حساب فوري للتكاليف وتوصيات المساحة المناسبة\n\n🌡️ **درجات حرارة التخزين**\n• التخزين العادي (25°م)، المبرد (4°م)، والمجمد (-18°م)\n\n🚚 **الشحنات والتوصيل**\n• تصاريح الدخول (STO) وبوالص الشحن Express (WAY)\n\n📜 **الامتثال والتراخيص**\n• ضريبة القيمة المضافة (5%) وتوثيق KYC\n\n💰 **سحوبات التاجر**\n• فترات الحجز (14 يوماً) وإجراءات السحب\n\nاختر من الأسئلة السريعة أدناه أو اكتب سؤالك مباشرة! 👇";
    } else {
      return "👋 Welcome to **NXN Copilot AI Assistant**! 🤖✨\n\nI am your 24/7 intelligent logistics & fulfillment advisor.\n\nHere is how I can assist you today:\n\n📦 **Micro-Warehousing & Space Subscriptions**\n• Instant shelf rental quotes & capacity recommendations\n\n🌡️ **Storage Temperature Classes**\n• Ambient (25°C), Chilled (4°C), Cold (-18°C) specs\n\n🚚 **Inbound & Outbound Logistics**\n• Gate Pass (STO) scheduling & Courier Express (WAY)\n\n📜 **Compliance & Trade License**\n• UAE FTA Tax rules (5% VAT) & KYC verification\n\n💰 **Merchant Financials**\n• 14-day seller hold periods & payout processing\n\nTap any prompt below or type your question! 👇";
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final query = userQuery.toLowerCase();

    // Check for explicit quarantine visual alert card request
    if (query.contains("quarantine") || query.contains("rtv") || query.contains("تالف") || query.contains("عزل") || query.contains("حجر")) {
      final text = isAr
          ? "⚠️ **بروتوكول البضائع التالفة والعزل في مستودعات NXN:**\n\n"
              "عند حدوث تلف أثناء الفحص الوارد أو داخل المستودع:\n"
              "1. **العزل في النظام:** تحول حالة المنتجات إلى `quarantine` وتخفى فوراً من نتائج البحث وسلات التجميع بالسوق.\n"
              "2. **العزل الفعلي:** تُنقل المنتجات إلى منطقة الحجر المخصصة بالمركز.\n"
              "3. **التعويض المالي:** عند التلف بسبب عمليات المستودع، يتم رصيد القيمة البيعية كاملة بمحفظتك.\n"
              "4. **خيارات التصرف:** خروج البضائع RTV، الإتلاف المصرح، أو إعادة الإدراج بسعر مخفض."
          : "⚠️ **Damaged Goods & Quarantine Protocol (NXN Hub):**\n\n"
              "When inventory is damaged during inbound receiving or hub relocation:\n"
              "1. **System Lock:** Item status updates to `quarantine` and is immediately hidden from marketplace search & picklists.\n"
              "2. **Physical Isolation:** Moved to the hub Quarantine Hold Area.\n"
              "3. **Financial Attribution:** If damaged by warehouse ops, **full retail credit** is issued to your Wallet.\n"
              "4. **Disposition Paths:** Choose RTV Return, Authorized Disposal, or Refurbished Liquidation.";

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: text,
            isUser: false,
            timestamp: DateTime.now(),
            cardType: ChatCardType.damagedQuarantineAlert,
            cardData: {
              'hub': 'DXB Hub (Bay 3)',
              'sku': 'SKU-DXB-002',
              'product_name': 'Arabian Coffee Blend',
              'damaged_qty': 2,
              'reason': 'Packaging damage during hub forklift relocation',
              'compensation': 70.0,
            },
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    // 1. First, check official Excel matrix via ChatbotEngine
    final engineResponse = await _chatbotEngine.processMessage(userQuery, isAr: isAr);
    String responseText = engineResponse.text;

    // 2. If the query was broad or triggered fallback, enrich with our detailed domain answers
    final isFallbackNotice = responseText.contains("لم أجد مطابقة") || responseText.contains("predefined rules");

    if (isFallbackNotice) {
      if (query.contains("price") || query.contains("pricing") || query.contains("cost") || query.contains("fee") || query.contains("100") ||
          query.contains("سعر") || query.contains("أسعار") || query.contains("تكلفة") || query.contains("رسوم") || query.contains("إيجار")) {
        responseText = isAr
            ? "📌 **هيكل أسعار التخزين الدقيق في NXN:**\n\n"
                "• **السعر الأساسي للرف:** 100 درهم لكل رف شهرياً في جميع مراكز التجميع الـ4 بالدولة (دبي، أبوظبي، الشارقة، العين).\n"
                "• **رسوم مساعدة العمال:** +50 درهم لكل عامل مخصص.\n"
                "• **رسوم المنصة:** 5% من المجموع الفرعي.\n"
                "• **ضريبة القيمة المضافة:** 5% محتسبة وفقاً لقوانين هيئة الضرائب بالدولة.\n\n"
                "يمكنك تخصيص مساحتك وحساب التكلفة بدقة في تبويب **حجز مساحة**!"
            : "📌 **NXN Micro-Warehousing Pricing Structure:**\n\n"
                "• **Base Shelf Rate:** AED 100 per shelf per month across all 4 UAE fulfillment hubs (Dubai, Abu Dhabi, Sharjah, Al Ain).\n"
                "• **Worker Assistance Fee:** +50 AED per worker assigned.\n"
                "• **Platform Fee:** 5% of subtotal.\n"
                "• **UAE VAT:** 5% value-added tax calculated on the subtotal and platform fee.\n\n"
                "You can customize your space and calculate exact quotes anytime in the **Book Space** tab!";
      } else if (query.contains("temp") || query.contains("chilled") || query.contains("cold") || query.contains("ambient") ||
          query.contains("حرارة") || query.contains("تبريد") || query.contains("تجميد") || query.contains("مبرد") || query.contains("بارد")) {
        responseText = isAr
            ? "🌡️ **فئات درجات حرارة التخزين ومضاعفات الأسعار:**\n\n"
                "1. **التخزين العادي (1.0x الأساسي):** مساحات مجهزة ومكيفة للبضائع العامة غير القابلة للتلف.\n"
                "2. **التخزين المبرد (+30% زيادة):** حرارة ثابتة بين 2°C – 8°C لمستحضرات التجميل والمشروبات والمنتجات الحساسة.\n"
                "3. **التخزين المجمد (+50% زيادة):** تخزين تحت الصفر للبضائع القابلة للتلف والأغذية والمواد التخصصية."
            : "🌡️ **Storage Temperature Classes & Pricing Multipliers:**\n\n"
                "1. **Ambient Storage (1.0x Base):** Standard climate-controlled warehouse space for non-perishable goods.\n"
                "2. **Chilled Storage (+30% Rate):** Temperature maintained between 2°C – 8°C for cosmetics, beverages, and sensitive items.\n"
                "3. **Cold Storage (+50% Rate):** Frozen storage below 0°C for perishables and specialized cargo.";
      } else if (query.contains("kyc") || query.contains("license") || query.contains("trn") || query.contains("document") ||
          query.contains("رخصة") || query.contains("ترخيص") || query.contains("تحقق") || query.contains("وثائق") || query.contains("مستندات")) {
        responseText = isAr
            ? "📜 **متطلبات التحقق والـ KYC للتجار بالدولة:**\n\n"
                "لتصبح تاخراً معتمداً في سوق NXN، يجب تقديم:\n"
                "• **رخصة تجارية إماراتية سارية** أو رخصة اعتماد إلكتروني.\n"
                "• **الهوية الإماراتية** (الوجهين).\n"
                "• **الرقم الضريبي TRN (15 رقم)** للالتزام بالفواتير الإلكترونية لـ FTA.\n\n"
                "يتم مراجعة الطلبات والاعتماد خلال 24–48 ساعة عمل."
            : "📜 **UAE Merchant Verification & KYC Requirements:**\n\n"
                "To become a verified seller on the NXN Marketplace, merchants must submit:\n"
                "• **Valid UAE Trade License** or E-Trader License.\n"
                "• **Emirates ID** (Front & Back).\n"
                "• **15-Digit FTA Tax Registration Number (TRN)** for e-invoicing compliance.\n\n"
                "Once submitted, verification is reviewed within 24–48 business hours.";
      } else if (query.contains("payout") || query.contains("iban") || query.contains("withdraw") || query.contains("settle") ||
          query.contains("أرباح") || query.contains("سحب") || query.contains("محفظة") || query.contains("تحويل") || query.contains("رصيد")) {
        responseText = isAr
            ? "💰 **محرك سحب أرباح التجار عبر الحساب البنكي (IBAN):**\n\n"
                "• **فترة تعليق 14 يوماً:** تخضع مبيعاتك لفترة تعليق قياسية مدتها 14 يوماً لضمان انتهاء مهلة الإرجاع.\n"
                "• **صافي الأرباح:** يتم تحويل 95% من صافي المبيعات مباشرة إلى حسابك البنكي المسجل (5% عمولة المنصة).\n"
                "• يمكنك طلب سحب الأرباح في أي وقت مباشرة من **صفحة المحفظة**."
            : "💰 **Seller IBAN Payout Engine:**\n\n"
                "• **14-Day Clearance Hold:** Sales revenue undergoes a standard 14-day clearance hold to accommodate return windows.\n"
                "• **Net Payout:** 95% net payout transferred directly to your registered UAE IBAN (5% platform commission).\n"
                "• You can request payouts anytime directly from your **Wallet Page**.";
      }
    }

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          cardType: ChatCardType.none,
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
                  isArCurrent ? "المساعد الذكي NXN" : "NXN Copilot",
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
            {"label": "🌡️ ما هي فئات درجات حرارة التخزين؟", "query": "ما هي فئات درجات حرارة التخزين؟"},
            {"label": "📜 ما المستندات المطلوبة للتحقق (KYC)؟", "query": "ما هي المستندات والبيانات المطلوبة للتحقق (KYC)؟"},
            {"label": "💰 كيف تعمل سحوبات الأرباح للتاجر (14 يوماً)؟", "query": "كيف تعمل سحوبات الأرباح للتاجر (14 يوماً) للحساب البنكي؟"},
          ]
        : [
            {"label": "❓ How is shelf rental pricing calculated?", "query": "How is shelf rental pricing and subscription calculated?"},
            {"label": "🌡️ What are the storage temperature classes?", "query": "What are the storage temperature classes?"},
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
                        hintText: isAr ? "اكتب سؤالك عن الخدمات اللوجستية والتخزين..." : "Type a logistics question or command...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
