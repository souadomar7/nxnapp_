import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';

// States
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthEmailVerificationSent extends AuthState {
  final String email;
  const AuthEmailVerificationSent(this.email);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const AuthInitial());

  Future<void> checkSession() async {
    final user = _repository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      final res = await _repository.signInWithEmail(email, password);
      if (res.user != null) {
        emit(AuthAuthenticated(res.user!));
      } else {
        emit(const AuthError('Login failed: Invalid credentials'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    emit(const AuthLoading());
    try {
      final res = await _repository.signUpWithEmail(email, password, fullName);
      if (res.session == null) {
        emit(AuthEmailVerificationSent(email));
      } else if (res.user != null) {
        emit(AuthAuthenticated(res.user!));
      } else {
        emit(const AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());
    try {
      await _repository.resetPassword(email);
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
