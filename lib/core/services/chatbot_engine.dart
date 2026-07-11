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

  Future<ChatMessage> processMessage(String userMessage) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 1. Handle pending intent (waiting for required data)
    if (_pendingIntent != null) {
      return _handlePendingIntent(userMessage);
    }

    // 2. Deterministic Matching
    final intent = _findBestMatch(userMessage);
    
    if (intent != null) {
      return _handleIntent(intent);
    }

    // 3. Fallback to LLM if no deterministic match found
    try {
      final llmResponse = await _llmService.processFallback(userMessage, _intents);
      return ChatMessage(
        text: llmResponse,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        text: "I'm sorry, I'm having trouble understanding right now. Please try again or contact support.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }
  }

  ChatbotIntent? _findBestMatch(String message) {
    message = message.toLowerCase().trim();
    final msgClean = message.replaceAll(RegExp(r'[?؟.,!]'), '');
    
    int maxMatches = 0;
    ChatbotIntent? bestIntent;

    for (var intent in _intents) {
      int matches = 0;

      // 1. Exact or partial Question match (Highest Priority)
      final qEnClean = intent.questionEn.toLowerCase().replaceAll(RegExp(r'[?؟.,!]'), '').trim();
      final qArClean = intent.questionAr.toLowerCase().replaceAll(RegExp(r'[?؟.,!]'), '').trim();

      if (qEnClean.isNotEmpty && (msgClean == qEnClean || msgClean.contains(qEnClean) || qEnClean.contains(msgClean))) {
        matches += 50;
      }
      if (qArClean.isNotEmpty && (msgClean == qArClean || msgClean.contains(qArClean) || qArClean.contains(msgClean))) {
        matches += 50;
      }

      // 2. Keyword matching
      for (var kw in intent.keywordsEn) {
        if (kw.isNotEmpty && message.contains(kw.toLowerCase())) {
          matches++;
        }
      }
      // Match Arabic keywords
      for (var kw in intent.keywordsAr) {
        if (kw.isNotEmpty && message.contains(kw)) {
          matches++;
        }
      }

      // 3. Word matching from the question to catch variations
      final words = msgClean.split(' ').where((w) => w.length > 3).toList();
      for (var word in words) {
        if (qEnClean.contains(word) || qArClean.contains(word)) {
          matches++;
        }
      }

      if (matches > maxMatches) {
        maxMatches = matches;
        bestIntent = intent;
      }
    }

    // Require a reasonable threshold if it's just word matching, or >0 if it's keywords/exact
    return maxMatches > 0 ? bestIntent : null;
  }

  ChatMessage _handleIntent(ChatbotIntent intent) {
    if (intent.botActionEn == 'Collect data then proceed') {
      _pendingIntent = intent;
      return ChatMessage(
        text: "Please provide your ${intent.requiredDataEn.toLowerCase()}: \n(يرجى تزويدنا بـ ${intent.requiredDataAr})",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    if (intent.escalate) {
      return ChatMessage(
        text: "This requires human support. Escalation reason: ${intent.escalationReasonEn}. \n\nI will escalate this ticket now.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    return ChatMessage(
      text: "${intent.answerEn}\n\n${intent.answerAr}",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _handlePendingIntent(String data) {
    final intent = _pendingIntent!;
    _pendingIntent = null; // Clear pending state
    
    // In a real app, you would send this data to your backend/ticketing system here.
    if (intent.escalate) {
      return ChatMessage(
        text: "Thank you for providing the details. A support agent will contact you shortly regarding: ${intent.escalationReasonEn}.",
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
    }

    return ChatMessage(
      text: "Thank you. We have received your data and are processing your request.",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }
}
