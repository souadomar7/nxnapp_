class ChatbotIntent {
  final int id;
  final String categoryAr;
  final String categoryEn;
  final String intentAr;
  final String intentEn;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final List<String> keywordsAr;
  final List<String> keywordsEn;
  final String requiredDataAr;
  final String requiredDataEn;
  final String botActionAr;
  final String botActionEn;
  final bool escalate;
  final String escalationReasonAr;
  final String escalationReasonEn;
  final String priority;

  ChatbotIntent({
    required this.id,
    required this.categoryAr,
    required this.categoryEn,
    required this.intentAr,
    required this.intentEn,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.keywordsAr,
    required this.keywordsEn,
    required this.requiredDataAr,
    required this.requiredDataEn,
    required this.botActionAr,
    required this.botActionEn,
    required this.escalate,
    required this.escalationReasonAr,
    required this.escalationReasonEn,
    required this.priority,
  });

  factory ChatbotIntent.fromJson(Map<String, dynamic> json) {
    return ChatbotIntent(
      id: json['id'] ?? 0,
      categoryAr: json['categoryAr'] ?? '',
      categoryEn: json['categoryEn'] ?? '',
      intentAr: json['intentAr'] ?? '',
      intentEn: json['intentEn'] ?? '',
      questionAr: json['questionAr'] ?? '',
      questionEn: json['questionEn'] ?? '',
      answerAr: json['answerAr'] ?? '',
      answerEn: json['answerEn'] ?? '',
      keywordsAr: List<String>.from(json['keywordsAr'] ?? []),
      keywordsEn: List<String>.from(json['keywordsEn'] ?? []),
      requiredDataAr: json['requiredDataAr'] ?? '',
      requiredDataEn: json['requiredDataEn'] ?? '',
      botActionAr: json['botActionAr'] ?? '',
      botActionEn: json['botActionEn'] ?? '',
      escalate: json['escalate'] ?? false,
      escalationReasonAr: json['escalationReasonAr'] ?? '',
      escalationReasonEn: json['escalationReasonEn'] ?? '',
      priority: json['priority'] ?? '',
    );
  }
}
