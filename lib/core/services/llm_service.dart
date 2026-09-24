import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chatbot_intent.dart';

class LlmService {
  /// Processes the user's message using an LLM when the deterministic matcher fails.
  /// Passes the available intents as context so the LLM can extract intent or answer safely.
  Future<String> processFallback(String userMessage, List<ChatbotIntent> contextIntents, {bool isAr = false}) async {
    final isArabicQuery = isAr || RegExp(r'[\u0600-\u06FF]').hasMatch(userMessage);
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'PLACEHOLDER_KEY') {
      if (isArabicQuery) {
        return "🤖 **المساعد الذكي لـ NXN:**\n\nلم أجد مطابقة دقيقة لسؤالك في القواعد المعرّفة سابقاً. (يتطلب محرك الـ AI المتقدم مفتاح API). يرجى الاختيار من الأسئلة الشائعة أعلاه أو التواصل مع فريق الدعم الفني! 📞";
      }
      return "I am an AI assistant. I didn't find an exact match for your question in my predefined rules. (LLM Fallback requires a valid API Key). Please contact support.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash-lite',
        apiKey: apiKey,
      );

      // Extract a summary of intents to guide the LLM
      final String intentSummary = contextIntents.map((intent) {
        return isArabicQuery
            ? "- ${intent.intentAr} (${intent.categoryAr}): ${intent.answerAr}"
            : "- ${intent.intentEn} (${intent.categoryEn}): ${intent.answerEn}";
      }).join('\n');

      final prompt = isArabicQuery
          ? '''
أنت المساعد الذكي لشركة "خزن ووصل" (NXN) لإدارة المستودعات والخدمات اللوجستية والتوصيل في الإمارات.
سؤال المستخدم: "$userMessage"

إليك بعض الإرشادات والإجابات المعرفة مسبقاً:
$intentSummary

تعليمات هامة جداً (التزام إجباري):
1. يجب أن تكون إجابتك بالكامل (100%) باللغة العربية الفصحى الواضحة والمهنية.
2. ترجم جميع المصطلحات والأسعار والخدمات إلى العربية.
3. إذا كان سؤال المستخدم يتعلق بالتخزين، الأسعار (100 درهم/رف)، التبريد، السحب البنكي (14 يوماً)، أو تصاريح الدخول STO/WAY، أجب بدقة واستناداً للإرشادات.
4. حافظ على إجابة مختصرة، منظمة ومفيدة جداً للتاجر.
'''
          : '''
You are a helpful customer support AI for "Khazen w Wasel" (NXN), an inventory and fulfillment company.
The user asked: "$userMessage"

Here are some of your known guidelines and answers:
$intentSummary

Instructions:
1. If you can answer the user's question clearly based ON THE GUIDELINES PROVIDED ABOVE, do so politely.
2. If the user is just saying a general greeting, greet them back and ask how you can help them with their fulfillment or inventory needs.
3. If the user is asking something completely unrelated or you cannot find an answer based on your guidelines, politely state that you cannot help with this request and offer to escalate to a human agent.
4. Respond strictly in English.
5. Keep your response concise, friendly, and professional.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text ?? (isArabicQuery
          ? "عذراً، لم أتمكن من الحصول على إجابة محددة. يرجى المحاولة مرة أخرى."
          : "I apologize, I am having trouble processing your request.");
    } catch (e) {
      debugPrint('LLM Error: $e');
      return isArabicQuery
          ? "عذراً، أواجه صعوبة مؤقتة في الإجابة حالياً. يرجى المحاولة مرة أخرى أو التواصل مع خدمة العملاء."
          : "I apologize, but I am experiencing temporary technical difficulties answering your question. Please try again or request to speak to an agent.";
    }
  }
}
