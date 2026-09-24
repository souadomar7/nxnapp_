import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/wallet_repository.dart';

// States
abstract class WalletState {
  const WalletState();
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final double balance;
  final List<Map<String, dynamic>> transactions;

  const WalletLoaded({
    required this.balance,
    required this.transactions,
  });
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
}

// Cubit
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _repository;

  WalletCubit({WalletRepository? repository})
      : _repository = repository ?? WalletRepository(),
        super(const WalletInitial());

  Future<void> load() async {
    emit(const WalletLoading());
    try {
      final balance = await _repository.getBalance();
      final txs = await _repository.getTransactions();
      emit(WalletLoaded(balance: balance, transactions: txs));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> refresh() async {
    try {
      final balance = await _repository.getBalance();
      final txs = await _repository.getTransactions();
      emit(WalletLoaded(balance: balance, transactions: txs));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
