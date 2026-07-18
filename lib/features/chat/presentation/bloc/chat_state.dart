import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<ChatMessage> history;

  const ChatLoading(this.history);

  @override
  List<Object?> get props => [history];
}

class ChatSuccess extends ChatState {
  final List<ChatMessage> history;

  const ChatSuccess(this.history);

  @override
  List<Object?> get props => [history];
}

class ChatFailure extends ChatState {
  final String errorMessage;
  final List<ChatMessage> history;

  const ChatFailure({
    required this.errorMessage,
    required this.history,
  });

  @override
  List<Object?> get props => [errorMessage, history];
}
