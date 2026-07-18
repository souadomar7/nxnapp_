import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/chat_gateway_source.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatGatewaySource _chatGatewaySource;
  final List<ChatMessage> _messageHistory = [];

  ChatBloc({
    required ChatGatewaySource chatGatewaySource,
  })  : _chatGatewaySource = chatGatewaySource,
        super(ChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.messageText.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: event.messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messageHistory.add(userMsg);
    emit(ChatLoading(List.from(_messageHistory)));

    try {
      final aiReply = await _chatGatewaySource.getAiReply(event.messageText);
      final botMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: aiReply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messageHistory.add(botMsg);
      emit(ChatSuccess(List.from(_messageHistory)));
    } catch (e) {
      emit(ChatFailure(
        errorMessage: 'Support gateway error: $e',
        history: List.from(_messageHistory),
      ));
    }
  }
}
