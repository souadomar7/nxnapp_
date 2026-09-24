import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/booking_repository.dart';

// States
abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingLoaded extends BookingState {
  final List<Map<String, dynamic>> warehouses;
  final List<Map<String, dynamic>> activeSubscriptions;

  const BookingLoaded({
    required this.warehouses,
    required this.activeSubscriptions,
  });
}

class BookingSuccess extends BookingState {
  final String subscriptionId;
  const BookingSuccess(this.subscriptionId);
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}

// Cubit
class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _repository;

  BookingCubit({BookingRepository? repository})
      : _repository = repository ?? BookingRepository(),
        super(const BookingInitial());

  Future<void> load() async {
    emit(const BookingLoading());
    try {
      final warehouses = await _repository.getWarehouses();
      final activeSubs = await _repository.getActiveSubscriptions();
      emit(BookingLoaded(
        warehouses: warehouses,
        activeSubscriptions: activeSubs,
      ));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> createBooking({
    required String warehouseId,
    required int shelvesCount,
    required int months,
    required String storageType,
    bool addWorkers = false,
    int workerCount = 0,
  }) async {
    emit(const BookingLoading());
    try {
      final subId = await _repository.createBookingRecord(
        warehouseId: warehouseId,
        shelvesCount: shelvesCount,
        months: months,
        storageType: storageType,
        addWorkers: addWorkers,
        workerCount: workerCount,
      );
      emit(BookingSuccess(subId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> cancelSubscription(String subscriptionId, {String? reason}) async {
    try {
      await _repository.cancelSubscription(subscriptionId, reason: reason);
      await load();
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
