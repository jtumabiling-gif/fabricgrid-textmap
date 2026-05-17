import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/role_controller.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // Get the selected role from RoleController
      final roleController = Get.find<RoleController>();
      final selectedRole = roleController.getRole();

      if (selectedRole == null) {
        throw 'Please select a role first';
      }

      await _authService.signIn(email: email, password: password);
      
      // Get user ID and verify role
      final userId = _authService.userId;
      if (userId != null) {
        // Check if user exists in the selected role collection
        final hasRoleAccess = await _userProfileService.verifyUserRoleAccess(
          userId: userId,
          role: selectedRole,
        );

        if (!hasRoleAccess) {
          // User exists but not in the selected role collection
          // Check if user has ANY role assigned
          final userRole = await _userProfileService.getUserRole(userId);
          if (userRole != null && userRole != selectedRole) {
            // User has different role than selected - sign out and show error
            await _authService.signOut();
            throw 'The email address is invalid';
          }
          // If user has no role info or just created account, allow login to proceed
        }

        // Load user role from Firestore to confirm it exists
        final userRole = await _userProfileService.getUserRole(userId);
        if (userRole != null) {
          roleController.setRole(userRole);
        }
      }
      
      if (mounted) {
        // Get user display name for welcome message
        final user = _authService.currentUser;
        final userName = user?.displayName ?? 'Welcome';
        
        // Show welcome snackbar based on role
        final roleController = Get.find<RoleController>();
        final role = roleController.getRole();
        
        var welcomeTitle = 'Welcome!';
        var welcomeMessage = 'You have successfully signed in';
        
        switch (role) {
          case UserRole.user:
            welcomeTitle = 'Welcome, $userName!';
            welcomeMessage = 'You are now signed in to Customer Dashboard';
            break;
          case UserRole.shopOwner:
            welcomeTitle = 'Welcome, $userName!';
            welcomeMessage = 'You are now signed in to Shop Owner Dashboard';
            break;
          case UserRole.admin:
            welcomeTitle = 'Welcome, Admin!';
            welcomeMessage = 'You are now signed in to Admin Dashboard';
            break;
          case null:
            welcomeTitle = 'Welcome!';
            welcomeMessage = 'You have successfully signed in';
        }
        
        Get.snackbar(
          welcomeTitle,
          welcomeMessage,
          backgroundColor: const Color(0xFF1EDDAC),
          colorText: Colors.black87,
          duration: const Duration(seconds: 2),
        );
        
        Future.delayed(const Duration(milliseconds: 500), _navigateByRole);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if it's a connection error
        final isConnectionError = errorMessage.contains('connection') ||
            errorMessage.contains('Connection') ||
            errorMessage.contains('network') ||
            errorMessage.contains('Network') ||
            errorMessage.contains('I/O error');
        
        if (isConnectionError) {
          // Show error with retry option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _handleSignIn,
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // Regular error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole() {
    try {
      final roleController = Get.find<RoleController>();
      final role = roleController.getRole();

      switch (role) {
        case UserRole.user:
          Get.offAllNamed('/discover');
        case UserRole.shopOwner:
          Get.offAllNamed('/shop-owner-main');
        case UserRole.admin:
          Get.offAllNamed('/admin-main');
        case null:
          // If role is not set, default to discover
          Get.offAllNamed('/discover');
      }
    } catch (e) {
      // If controller is not found, default to discover
      Get.offAllNamed('/discover');
    }
  }

  String _getDashboardText() {
    try {
      final roleController = Get.find<RoleController>();
      final role = roleController.getRole();

      switch (role) {
        case UserRole.user:
          return 'Sign in to continue to Customer Dashboard';
        case UserRole.shopOwner:
          return 'Sign in to continue to Shop Owner Dashboard';
        case UserRole.admin:
          return 'Sign in to continue to Admin Dashboard';
        case null:
          return 'Sign in to continue to FabricGrid';
      }
    } catch (e) {
      return 'Sign in to continue to FabricGrid';
    }
  }

  Future<void> _launchGoogle() async {
    final Uri googleUrl = Uri.parse('https://www.google.com');
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchFacebook() async {
    final Uri facebookUrl = Uri.parse('https://www.facebook.com');
    try {
      if (await canLaunchUrl(facebookUrl)) {
        await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Facebook')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F1F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1F2F),
        title: const Text('Sign In', style: TextStyle(color: Colors.white)),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Get.offAllNamed('/role-selection');
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getDashboardText(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: Validators.validateEmail,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'name@example.com',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                    fillColor: const Color(0xFF1A2B3F),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1EDDAC)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  validator: Validators.validatePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    fillColor: const Color(0xFF1A2B3F),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1EDDAC)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // TODO: Implement forgot password functionality
                        },
                  child: Text(
                    'Forgot Password?',
                    style: AppTheme.bodySmall.copyWith(
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EDDAC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F1F2F),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _launchGoogle,
                      icon: const Icon(Icons.g_translate, color: Colors.white),
                      label: const Text('Google', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _launchFacebook,
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text('Facebook', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          color: Color(0xFF1EDDAC),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _isLoading ? null : () => Get.toNamed('/signup'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
}
