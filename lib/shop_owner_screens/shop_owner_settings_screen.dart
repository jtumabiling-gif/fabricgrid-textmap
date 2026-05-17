import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'shop_owner_balance_screen.dart';
import 'shop_owner_details_screen.dart';
import 'shop_owner_subscription_screen.dart';

class ShopOwnerSettingsScreen extends StatefulWidget {
  const ShopOwnerSettingsScreen({super.key});

  @override
  State<ShopOwnerSettingsScreen> createState() =>
      _ShopOwnerSettingsScreenState();
}

class _ShopOwnerSettingsScreenState extends State<ShopOwnerSettingsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      body: ListView(
        children: [
          // Shop Settings Section
          _buildSectionHeader('Shop Settings'),
          _buildListTile(
            icon: Icons.store,
            title: 'Shop Details',
            subtitle: 'Manage your shop information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopOwnerDetailsScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              _showChangePasswordDialog(context);
            },
          ),
          _buildListTile(
            icon: Icons.wallet,
            title: 'My Balance',
            subtitle: 'View commission and balance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopBalanceScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12),
          // Subscription Section
          _buildSectionHeader('Subscription'),
          _buildListTile(
            icon: Icons.card_membership,
            title: 'Manage Subscription',
            subtitle: 'View and upgrade your subscription plan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopOwnerSubscriptionScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12),
          // About & Support
          _buildSectionHeader('About & Support'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
            onTap: () => _showComingSoonDialog(context),
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'App version and information',
            onTap: () => _showComingSoonDialog(context),
          ),
          const Divider(color: Colors.white12),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showLogoutDialog(context),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1EDDAC),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: const Color(0xFF1EDDAC)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white54),
        onTap: onTap,
      );

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isLoading = false;
    var showCurrentPassword = false;
    var showNewPassword = false;
    var showConfirmPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            color: const Color(0xFF0F1F2F),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2B3F),
                    border: Border(
                      bottom: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Current Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: currentPasswordController,
                          enabled: !isLoading,
                          obscureText: !showCurrentPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your current password',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0F1F2F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showCurrentPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  showCurrentPassword = !showCurrentPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'New Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: newPasswordController,
                          enabled: !isLoading,
                          obscureText: !showNewPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your new password',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0F1F2F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  showNewPassword = !showNewPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Confirm New Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: !showConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Confirm your new password',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0F1F2F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1EDDAC),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer with buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2B3F),
                    border: Border(
                      top: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                // Validate inputs
                                if (currentPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your current password'),
                                    ),
                                  );
                                  return;
                                }

                                if (newPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a new password'),
                                    ),
                                  );
                                  return;
                                }

                                if (newPasswordController.text !=
                                    confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                    ),
                                  );
                                  return;
                                }

                                if (newPasswordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Password must be at least 6 characters'),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  // First, verify current password by re-authenticating
                                  final authService = AuthService();
                                  final user = authService.currentUser;

                                  if (user?.email == null) {
                                    throw 'Unable to get user email';
                                  }

                                  // Re-authenticate with current password
                                  await FirebaseAuth.instance.currentUser!
                                      .reauthenticateWithCredential(
                                    EmailAuthProvider.credential(
                                      email: user!.email!,
                                      password: currentPasswordController.text,
                                    ),
                                  );

                                  // Update password
                                  await authService.updatePassword(
                                    newPassword: newPasswordController.text,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Password changed successfully!'),
                                        backgroundColor:
                                            Color(0xFF1EDDAC),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  var errorMessage = 'Error changing password';
                                  if (e.toString().contains('wrong-password') ||
                                      e.toString().contains('invalid-credential')) {
                                    errorMessage =
                                        'Current password is incorrect';
                                  } else if (e
                                      .toString()
                                      .contains('weak-password')) {
                                    errorMessage =
                                        'New password is too weak';
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage)),
                                    );
                                  }
                                }

                                setDialogState(() {
                                  isLoading = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1EDDAC),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87,
                                  ),
                                ),
                              )
                            : const Text('Change Password'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature may be implemented in the future.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF1EDDAC)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B3F),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/role-selection');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}