import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {

  factory AuthService() => _instance;

  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  late FirebaseAuth _firebaseAuth;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Initialize Firebase Auth
  Future<void> initialize() async {
    if (_isInitialized) {
      await _initCompleter.future;
      return;
    }
    
    try {
      await Firebase.initializeApp();
      _firebaseAuth = FirebaseAuth.instance;
      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
  }
  
  /// Ensure Firebase is initialized before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get the current user
  User? get currentUser {
    if (!_isInitialized) return null;
    return _firebaseAuth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    if (!_isInitialized) return false;
    return _firebaseAuth.currentUser != null;
  }

  /// Get current user's UID
  String? get userId {
    if (!_isInitialized) return null;
    return _firebaseAuth.currentUser?.uid;
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (!_isInitialized) {
      return Stream.value(null);
    }
    return _firebaseAuth.authStateChanges();
  }

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    int maxRetries = 3,
  }) async {
    await _ensureInitialized();
    
    var retryCount = 0;
    Exception? lastException;
    
    while (retryCount < maxRetries) {
      try {
        // Add a small delay to ensure platform channels are ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create user account
        final userCredential =
            await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update user profile with full name
        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(fullName);
          await userCredential.user!.reload();
        }

        return userCredential;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        lastException = e as Exception;
        retryCount++;
        
        // Only retry on network errors
        if (e.toString().contains('Connection reset') || 
            e.toString().contains('SocketException') ||
            e.toString().contains('network') ||
            e.toString().contains('I/O error')) {
          if (retryCount < maxRetries) {
            // Exponential backoff: 500ms, 1s, 2s
            await Future.delayed(
              Duration(milliseconds: 500 * (1 << (retryCount - 1))),
            );
            continue;
          }
        } else {
          // Non-network error, throw immediately
          throw 'An unexpected error occurred: $e';
        }
      }
    }
    
    // If we get here, all retries failed
    print('Sign up failed after $maxRetries attempts: $lastException');
    throw 'An authentication error occurred: Unable to connect. Please check your internet connection and try again.';
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
    int maxRetries = 3,
  }) async {
    await _ensureInitialized();
    
    var retryCount = 0;
    Exception? lastException;
    
    while (retryCount < maxRetries) {
      try {
        // Add a small delay to ensure platform channels are ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        final userCredential =
            await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCredential;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (e) {
        lastException = e as Exception;
        retryCount++;
        
        // Only retry on network errors
        if (e.toString().contains('Connection reset') || 
            e.toString().contains('SocketException') ||
            e.toString().contains('network') ||
            e.toString().contains('I/O error')) {
          if (retryCount < maxRetries) {
            // Exponential backoff: 500ms, 1s, 2s
            await Future.delayed(
              Duration(milliseconds: 500 * (1 << (retryCount - 1))),
            );
            continue;
          }
        } else {
          // Non-network error, throw immediately
          throw 'An unexpected error occurred: $e';
        }
      }
    }
    
    // If we get here, all retries failed
    print('Sign in failed after $maxRetries attempts: $lastException');
    throw 'An authentication error occurred: Unable to connect. Please check your internet connection and try again.';
  }

  /// Sign out
  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _ensureInitialized();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send reset email: $e';
    }
  }

  /// Update user password
  Future<void> updatePassword({required String newPassword}) async {
    await _ensureInitialized();
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password: $e';
    }
  }

  /// Change password with current password verification
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _ensureInitialized();
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      final email = user.email;
      if (email == null) {
        throw 'User email not found';
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to change password: $e';
    }
  }

  /// Update admin profile (display name and phone number)
  Future<void> updateAdminProfile({
    required String displayName,
    required String phoneNumber,
  }) async {
    await _ensureInitialized();
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(displayName);

      // Reload user to get updated info
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    await _ensureInitialized();
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-credential':
        return 'The credentials are invalid.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
