import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_controller.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1EDDAC),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'FABRIC GRID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1EDDAC),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'How will you use\nFabric Grid?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                const Text(
                  'Select your primary role to customize your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Three roles in horizontal layout
                Row(
                  children: [
                    // Customer Role Card
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: _buildCompactRoleCard(
                          role: 'customer',
                          icon: Icons.person,
                          title: 'Users',
                          isSelected: _selectedRole == 'customer',
                          onTap: () {
                            _selectedRole = 'customer';
                            _navigateByRole(_selectedRole!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Shop Owner Role Card
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: _buildCompactRoleCard(
                          role: 'shop_owner',
                          icon: Icons.store,
                          title: 'Shop Owner',
                          isSelected: _selectedRole == 'shop_owner',
                          onTap: () {
                            _selectedRole = 'shop_owner';
                            _navigateByRole(_selectedRole!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Admin Role Card
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: _buildCompactRoleCard(
                          role: 'admin',
                          icon: Icons.admin_panel_settings,
                          title: 'Admin',
                          isSelected: _selectedRole == 'admin',
                          onTap: () {
                            _showAdminVerificationDialog();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _buildCompactRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1EDDAC) : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A2B3F).withOpacity(0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3F4F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1EDDAC),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Check indicator
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1EDDAC),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF0F1F2F),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );

  void _navigateByRole(String roleString) {
    final roleController = Get.find<RoleController>();
    roleController.setRoleFromString(roleString);
    Get.offAllNamed('/login');
  }

  void _showAdminVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        title: const Text(
          'Admin Access',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Admin access requires verification.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'To proceed as an Admin, you will need to:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• Create a secure account with a strong password\n'
                '• Verify your email address\n'
                '• Complete identity verification\n'
                '• Await administrative approval',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This ensures the security and integrity of the platform.',
                style: TextStyle(
                  color: Color(0xFF1EDDAC),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _selectedRole = 'admin';
              _navigateByRole(_selectedRole!);
            },
            child: const Text(
              'Proceed',
              style: TextStyle(color: Color(0xFF1EDDAC)),
            ),
          ),
        ],
      ),
    );
  }
}
