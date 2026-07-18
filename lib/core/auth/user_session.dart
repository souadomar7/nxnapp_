import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_role.dart';

class UserSession {
  final String? userId;
  final String? email;
  final String? displayName;
  final UserRole role;
  final User? rawUser;

  const UserSession({
    this.userId,
    this.email,
    this.displayName,
    required this.role,
    this.rawUser,
  });

  /// Factory constructor to extract UserRole from Supabase metadata/claims securely.
  factory UserSession.fromSupabaseUser(User? user) {
    if (user == null) {
      return const UserSession(role: UserRole.guest);
    }

    final metadata = user.appMetadata;
    final roleString = metadata['role'] ?? metadata['user_role'] ?? 'merchant';

    UserRole assignedRole;
    if (roleString == 'operator' || roleString == 'admin') {
      assignedRole = UserRole.operator;
    } else if (roleString == 'guest') {
      assignedRole = UserRole.guest;
    } else {
      assignedRole = UserRole.merchant;
    }

    return UserSession(
      userId: user.id,
      email: user.email,
      displayName: user.userMetadata?['business_name'] ?? user.userMetadata?['name'] ?? 'Merchant User',
      role: assignedRole,
      rawUser: user,
    );
  }

  bool get isGuest => role == UserRole.guest;
  bool get isMerchant => role == UserRole.merchant;
  bool get isOperator => role == UserRole.operator;
}
