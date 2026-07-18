import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String messageText;

  const SendMessageEvent(this.messageText);

  @override
  List<Object?> get props => [messageText];
}
