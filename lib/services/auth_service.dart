// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Returns the locally-stored AppUser if Firebase has a valid session.
  // Signs out of Firebase and returns null if the Isar profile is missing
  // (e.g. fresh install on a new device).
  Future<AppUser?> checkLoggedInUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;

    final user = await _db.getUserByEmail(fbUser.email ?? '');
    if (user == null) {
      await _firebaseAuth.signOut();
      return null;
    }
    return user;
  }

  Future<AuthResult> login(String email, String password) async {
    final emailError = validateEmail(email);
    if (emailError != null) return AuthResult(success: false, message: emailError);
    if (password.isEmpty) return AuthResult(success: false, message: 'Password is required');

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = await _db.getUserByEmail(credential.user!.email!);
      if (user == null) {
        // Firebase account exists but Isar profile is missing (new device).
        // Sign out and tell the user to register again to rebuild the profile.
        await _firebaseAuth.signOut();
        return AuthResult(
          success: false,
          message: 'Profile not found. Please sign up again to restore your account.',
        );
      }

      user.lastLogin = DateTime.now();
      await _db.updateUser(user);

      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapFirebaseError(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Login failed. Please try again.');
    }
  }

  Future<AuthResult> signup(String name, String email, String password) async {
    if (name.trim().isEmpty) return AuthResult(success: false, message: 'Please enter your name');

    final emailError = validateEmail(email);
    if (emailError != null) return AuthResult(success: false, message: emailError);

    final passwordError = validatePassword(password);
    if (passwordError != null) return AuthResult(success: false, message: passwordError);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Store the display name in Firebase
      await credential.user?.updateDisplayName(name.trim());

      // Reuse an existing Isar profile if one was created by an older local-auth
      // account — this preserves transaction history after re-registration.
      AppUser? user = await _db.getUserByEmail(credential.user!.email!);
      if (user == null) {
        user = AppUser(
          email: credential.user!.email!,
          name: name.trim(),
          lastLogin: DateTime.now(),
        );
        await _db.saveUser(user);
        // Reload so Isar auto-increments the id
        user = await _db.getUserByEmail(credential.user!.email!);
      } else {
        // Update the name in case it changed
        user.name = name.trim();
        user.lastLogin = DateTime.now();
        await _db.updateUser(user);
      }

      return AuthResult(success: true, user: user, message: 'Account created successfully!');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapFirebaseError(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Signup failed. Please try again.');
    }
  }

  Future<void> logout(AppUser user) async {
    await _firebaseAuth.signOut();
  }

  Future<void> deleteAccount(AppUser user) async {
    await _firebaseAuth.currentUser?.delete();
    await _db.isar.writeTxn(() async {
      await _db.isar.appUsers.delete(user.id);
    });
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null;
  }

  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) return 'Enter a valid email address';
    return null;
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'network-request-failed':
        return 'No internet connection. Please try again';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled. Contact support';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final AppUser? user;

  AuthResult({required this.success, this.message, this.user});
}
