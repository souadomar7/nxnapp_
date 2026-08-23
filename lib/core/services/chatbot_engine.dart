import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/chatbot_intent.dart';
import '../models/chat_message.dart';
import 'llm_service.dart';

class ChatbotEngine {
  List<ChatbotIntent> _intents = [];
  bool _isInitialized = false;
  ChatbotIntent? _pendingIntent;
  final LlmService _llmService = LlmService();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/chatbot_matrix.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _intents = jsonList.map((e) => ChatbotIntent.fromJson(e)).toList();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to load chatbot matrix: $e');
    }
  }

  Future<ChatMessage> processMessage(String userMessage, {bool isAr = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final isArabicQuery = isAr || RegExp(r'[\u0600-\u06FF]').hasMatch(userMessage);

    // 1. Handle pending intent (waiting for required data)
    if (_pendingIntent != null) {
      return _handlePendingIntent(userMessage, isAr: isArabicQuery);
    }

    // 2. Deterministic Matching
    final intent = _findBestMatch(userMessage);
    
    if (intent != null) {
      return _handleIntent(intent, isAr: isArabicQuery);
    }

    // 3. Fallback to LLM if no deterministic match found
    try {
      final llmResponse = await _llmService.processFallback(userMessage, _intents, isAr: isArabicQuery);
      return ChatMessage(
        text: llmResponse,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        text: isArabicQuery
            ? "عذراً، أواجه صعوبة في فهم الطلب حالياً. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني."
            : "I'm sorry, I'm having trouble understanding right now. Please try again or contact support.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }
  }

  ChatbotIntent? _findBestMatch(String message) {
    final cleanMsg = _normalizeAr(message);
    if (cleanMsg.isEmpty) return null;
    final msgWords = cleanMsg.split(' ').where((w) => w.isNotEmpty).toSet();

    double maxScore = 0;
    ChatbotIntent? bestIntent;

    for (var intent in _intents) {
      final qArClean = _normalizeAr(intent.questionAr);
      final qEnClean = _normalizeAr(intent.questionEn);

      double score = 0;

      // 1. Exact Question Match (Highest Weight: 1000 points)
      if (cleanMsg == qArClean || cleanMsg == qEnClean) {
        score += 1000;
      }

      // 2. High partial match on questions
      final arWords = qArClean.split(' ').where((w) => w.isNotEmpty).toSet();
      final enWords = qEnClean.split(' ').where((w) => w.isNotEmpty).toSet();

      final overlapAr = msgWords.intersection(arWords).length;
      final overlapEn = msgWords.intersection(enWords).length;

      if (arWords.isNotEmpty) {
        score += (overlapAr / arWords.length) * 300;
      }
      if (enWords.isNotEmpty) {
        score += (overlapEn / enWords.length) * 300;
      }

      // 3. Keyword matches
      for (var kw in intent.keywordsAr) {
        final cleanKw = _normalizeAr(kw);
        if (cleanKw.isNotEmpty && cleanMsg.contains(cleanKw)) {
          score += 40;
        }
      }
      for (var kw in intent.keywordsEn) {
        final cleanKw = _normalizeAr(kw);
        if (cleanKw.isNotEmpty && cleanMsg.contains(cleanKw)) {
          score += 40;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestIntent = intent;
      }
    }

    return maxScore >= 40 ? bestIntent : null;
  }

  String _normalizeAr(String text) {
    text = text.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[\u064B-\u065F]'), ''); // remove tashkeel
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll(RegExp(r'[ة]'), 'ه');
    text = text.replaceAll(RegExp(r'[?؟.,!_]'), '');
    return text.trim();
  }

  String _normalizeSynonyms(String message) {
    // 1. Cost / Price / Fees (سعر / تكلفة / رسوم)
    final priceSynonymsAr = ['تكلفة', 'تكلفه', 'سعر', 'أسعار', 'اسعار', 'رسوم', 'مبلغ', 'قيمة', 'قيمه'];
    for (var synonym in priceSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' سعر تكلفة رسوم أسعار';
        break;
      }
    }
    final priceSynonymsEn = ['cost', 'price', 'pricing', 'fees', 'charges', 'rate', 'rates', 'fare'];
    for (var synonym in priceSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' cost price fees pricing';
        break;
      }
    }

    // 2. Warehouse / Storage / Shelves (مستودع / تخزين / مخزن)
    final storageSynonymsAr = ['مخزن', 'مخازن', 'مستودع', 'مستودعات', 'تخزين', 'خزن', 'رف', 'رفوف'];
    for (var synonym in storageSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' تخزين مستودع مخزن مخازن';
        break;
      }
    }
    final storageSynonymsEn = ['storage', 'warehouse', 'store', 'warehousing', 'depot', 'shelf', 'shelves'];
    for (var synonym in storageSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' storage warehouse store';
        break;
      }
    }

    // 3. Delivery / Shipping / Logistics (توصيل / شحن / ارسال)
    final deliverySynonymsAr = ['توصيل', 'شحن', 'ارسال', 'توزيع', 'طرد', 'بريد', 'ارساليات'];
    for (var synonym in deliverySynonymsAr) {
      if (message.contains(synonym)) {
        message += ' توصيل شحن ارسال طرد';
        break;
      }
    }
    final deliverySynonymsEn = ['delivery', 'shipping', 'ship', 'send', 'outbound', 'dispatch', 'courier', 'parcel'];
    for (var synonym in deliverySynonymsEn) {
      if (message.contains(synonym)) {
        message += ' delivery shipping outbound ship';
        break;
      }
    }

    // 4. Inbound / Receiving / Drop-off (استلام / توريد / ادخال)
    final inboundSynonymsAr = ['استلام', 'شحن للمخزن', 'توريد', 'ادخال', 'تنزيل', 'موعد', 'حجز'];
    for (var synonym in inboundSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' استلام توريد موعد حجز';
        break;
      }
    }
    final inboundSynonymsEn = ['receive', 'receiving', 'inbound', 'dropoff', 'arrival', 'appointment', 'booking'];
    for (var synonym in inboundSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' receive inbound dropoff booking';
        break;
      }
    }

    // 5. Account / Profile / KYC (حساب / تسجيل / توثيق)
    final accountSynonymsAr = ['حساب', 'تسجيل', 'توثيق', 'اشتراك', 'ملف', 'تفعيل', 'دخول', 'البيانات'];
    for (var synonym in accountSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' حساب تسجيل توثيق اشتراك';
        break;
      }
    }
    final accountSynonymsEn = ['account', 'register', 'signup', 'verify', 'verification', 'profile', 'login', 'kyc'];
    for (var synonym in accountSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' account register verification profile';
        break;
      }
    }

    // 6. Payment / Invoices / Billing (دفع / فواتير / سداد)
    final paymentSynonymsAr = ['دفع', 'فاتورة', 'فواتير', 'بطاقة', 'كرت', 'سداد', 'فيزا', 'رصيد'];
    for (var synonym in paymentSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' دفع فاتورة فواتير سداد';
        break;
      }
    }
    final paymentSynonymsEn = ['pay', 'payment', 'bill', 'billing', 'invoice', 'card', 'credit', 'visa', 'balance'];
    for (var synonym in paymentSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' pay payment bill invoice';
        break;
      }
    }

    // 7. Human Support / Customer Service (دعم / موظف / انسان)
    final supportSynonymsAr = ['دعم', 'موظف', 'انسان', 'شخص', 'مساعدة', 'تواصل', 'عملاء', 'مشكلة'];
    for (var synonym in supportSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' دعم موظف مساعدة تواصل';
        break;
      }
    }
    final supportSynonymsEn = ['support', 'human', 'agent', 'person', 'help', 'contact', 'chat', 'issue', 'problem'];
    for (var synonym in supportSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' support agent help contact';
        break;
      }
    }

    // 8. Products / Catalog / Items (منتج / بضاعة / اصناف)
    final productSynonymsAr = ['منتج', 'منتجات', 'بضاعة', 'بضائع', 'سلع', 'اغراض', 'اصناف', 'مخزون'];
    for (var synonym in productSynonymsAr) {
      if (message.contains(synonym)) {
        message += ' منتج منتجات بضاعة اصناف';
        break;
      }
    }
    final productSynonymsEn = ['product', 'products', 'item', 'items', 'goods', 'stock', 'cargo', 'catalog'];
    for (var synonym in productSynonymsEn) {
      if (message.contains(synonym)) {
        message += ' product item catalog stock';
        break;
      }
    }

    return message;
  }

  ChatMessage _handleIntent(ChatbotIntent intent, {bool isAr = false}) {
    if (intent.botActionEn == 'Collect data then proceed') {
      _pendingIntent = intent;
      return ChatMessage(
        text: isAr
            ? "📌 **[${intent.categoryAr}]**\n\n${intent.answerAr}\n\n📝 **مطلوب لتنفيذ الطلب:**\nيرجى تزويدنا بـ **${intent.requiredDataAr}** لمتابعة إجراءات الخدمة."
            : "📌 **[${intent.categoryEn}]**\n\n${intent.answerEn}\n\n📝 **Action Required:**\nPlease provide your **${intent.requiredDataEn}** to proceed with your request.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    if (intent.escalate) {
      return ChatMessage(
        text: isAr
            ? "📌 **[${intent.categoryAr}]**\n\n${intent.answerAr}\n\n🎧 **تنويه الدعم المباشر:**\nيتطلب هذا الاستفسار تواصل موظف خدمة العملاء.\n• **سبب التحويل:** ${intent.escalationReasonAr.isNotEmpty ? intent.escalationReasonAr : intent.escalationReasonEn}.\n\nتم رفع تذكرة الدعم وسيتم التواصل معك فوراً."
            : "📌 **[${intent.categoryEn}]**\n\n${intent.answerEn}\n\n🎧 **Support Escalation:**\nThis request requires human assistance.\n• **Reason:** ${intent.escalationReasonEn}.\n\nA support ticket has been opened for you.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    final categoryHeader = isAr
        ? (intent.categoryAr.isNotEmpty ? "📌 **[${intent.categoryAr}]**\n\n" : "")
        : (intent.categoryEn.isNotEmpty ? "📌 **[${intent.categoryEn}]**\n\n" : "");

    final mainAnswer = isAr ? intent.answerAr : intent.answerEn;
    final hint = _getAppHint(intent.categoryEn, isAr: isAr);

    return ChatMessage(
      text: "$categoryHeader$mainAnswer$hint",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }

  String _getAppHint(String categoryEn, {required bool isAr}) {
    final cat = categoryEn.toLowerCase();
    if (cat.contains('package') || cat.contains('price') || cat.contains('pricing') || cat.contains('fee')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك حساب التكلفة الدقيقة واختيار الباقة تحت تبويب **حجز مساحة** بالتطبيق."
          : "\n\n💡 *Note:* You can calculate exact quotes & select packages in the **Book Space** tab.";
    } else if (cat.contains('warehous') || cat.contains('storage') || cat.contains('inventory')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك متابعة مواقع الأرفف ومستويات المخزون تحت تبويب **المخزون الذكي**."
          : "\n\n💡 *Note:* You can monitor shelf allocations & SKU stock in the **Smart Inventory** tab.";
    } else if (cat.contains('inbound') || cat.contains('receiv') || cat.contains('intake')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك جدولة توريد الشحنات وحجز تصريح دخول العمال (STO) عبر **حجز تسليم البضائع**."
          : "\n\n💡 *Note:* Schedule intake drop-offs & gate passes via **Book Drop-off (STO)**.";
    } else if (cat.contains('outbound') || cat.contains('order') || cat.contains('ship') || cat.contains('deliver')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك إنشاء طلبات التوصيل وتتبع شركات الشحن من خلال **طلب شحن وتوصيل (WAY)**."
          : "\n\n💡 *Note:* Dispatch customer orders & track couriers in **Request Delivery (WAY)**.";
    } else if (cat.contains('pay') || cat.contains('bill') || cat.contains('wallet') || cat.contains('account')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك الاطلاع على الرصيد وطلب سحب الأرباح البنكية (IBAN) من **صفحة المحفظة**."
          : "\n\n💡 *Note:* Review cleared revenue & request IBAN payouts anytime on your **Wallet Page**.";
    } else if (cat.contains('return') || cat.contains('exchange') || cat.contains('quarantine')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* تخضع المنتجات المرتجعة للفحص مع توثيق حالات التعويض والعزل التلقائي بالمستودع."
          : "\n\n💡 *Note:* Returned items undergo inspection with auto-credit compensation for hub damages.";
    } else if (cat.contains('report') || cat.contains('analytic')) {
      return isAr
          ? "\n\n💡 *ملاحظة:* يمكنك تصدير تقارير التخزين والمبيعات بصيغة Excel أو PDF من لوحة التحليلات."
          : "\n\n💡 *Note:* Export fulfillment & sales reports anytime in Excel or PDF format.";
    }
    return "";
  }

  ChatMessage _handlePendingIntent(String data, {bool isAr = false}) {
    final intent = _pendingIntent!;
    _pendingIntent = null; // Clear pending state
    
    if (intent.escalate) {
      return ChatMessage(
        text: isAr
            ? "شكراً لك على تزويدنا بالتفاصيل. سيتواصل معك أحد ممثلي الدعم الفني قريباً بشأن: ${intent.escalationReasonAr.isNotEmpty ? intent.escalationReasonAr : intent.escalationReasonEn}."
            : "Thank you for providing the details. A support agent will contact you shortly regarding: ${intent.escalationReasonEn}.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    return ChatMessage(
      text: isAr
          ? "شكراً لك. لقد استلمنا بياناتك وجاري معالجة طلبك."
          : "Thank you. We have received your data and are processing your request.",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }
}
