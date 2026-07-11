enum MessageSender { user, bot }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isQuickReply;
  final List<String> quickReplies;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isQuickReply = false,
    this.quickReplies = const [],
  });
}
