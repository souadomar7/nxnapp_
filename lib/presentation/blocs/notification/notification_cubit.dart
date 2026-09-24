import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notification_repository.dart';

// States
abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
}

// Cubit
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(const NotificationInitial());

  Future<void> load() async {
    emit(const NotificationLoading());
    try {
      final items = await _repository.getNotifications();
      final unread = await _repository.getUnreadCount();
      emit(NotificationLoaded(notifications: items, unreadCount: unread));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repository.markAsRead(id);
      await load();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllAsRead();
      await load();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
