import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_role.dart';
import 'user_session.dart';

/// A state wrapper that reads the live Supabase session and resolves it
/// into a [UserSession] with the correct [UserRole], then passes it
/// to the [builder] so the rest of the UI can branch without knowing
/// anything about Supabase.
class SessionProvider extends InheritedWidget {
  final UserSession session;

  const SessionProvider({
    super.key,
    required this.session,
    required super.child,
  });

  static UserSession of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<SessionProvider>();
    return provider?.session ?? UserSession.guest;
  }

  @override
  bool updateShouldNotify(SessionProvider oldWidget) =>
      session.role != oldWidget.session.role ||
      session.userId != oldWidget.session.userId ||
      session.vendorStatus != oldWidget.session.vendorStatus ||
      session.isUaePassVerified != oldWidget.session.isUaePassVerified;
}

/// Wraps [child] and checks that the current session role belongs to
/// [allowedRoles]. If not, either collapses (when [showLockedUI] is false)
/// or renders a blurred "Sign Up to Unlock" placeholder.
class RoleViewGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final bool showLockedUI;
  final String? lockedLabel;
  final VoidCallback? onUnlockTap;

  const RoleViewGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.showLockedUI = true,
    this.lockedLabel,
    this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = SessionProvider.of(context);

    if (allowedRoles.contains(session.role)) return child;
    if (!showLockedUI) return const SizedBox.shrink();

    return _LockedPlaceholder(
      label: lockedLabel ?? 'Sign Up to Unlock',
      onTap: onUnlockTap,
      child: child,
    );
  }
}

class _LockedPlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget child;

  const _LockedPlaceholder({
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Render the actual widget but blur it out
        IgnorePointer(
          child: Opacity(opacity: 0.15, child: child),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E63FF).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Color(0xFF2E63FF), size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F3D),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E63FF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Sign Up Free',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Builds and injects a [SessionProvider] from the live Supabase user.
/// Place this high in the widget tree, wrapping the entire app shell.
class SessionProviderBuilder extends StatelessWidget {
  final Widget child;

  const SessionProviderBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final session = UserSession.fromSupabaseUser(supabaseUser);
    return SessionProvider(session: session, child: child);
  }
}
