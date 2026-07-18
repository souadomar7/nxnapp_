import 'package:flutter/material.dart';
import 'user_role.dart';

class RolePermissionShield extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final UserRole currentUserRole;
  final bool showDeniedUI;

  const RolePermissionShield({
    super.key,
    required this.child,
    required this.allowedRoles,
    required this.currentUserRole,
    this.showDeniedUI = true,
  });

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(currentUserRole)) {
      return child;
    }

    if (!showDeniedUI) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, size: 64, color: Colors.red.shade600),
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your account role (${currentUserRole.name.toUpperCase()}) does not possess the permissions required to view this interface.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
