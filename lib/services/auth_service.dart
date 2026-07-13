// File: lib/services/auth_service.dart
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _db = DatabaseService();

  // Check if any user is logged in
  Future<AppUser?> checkLoggedInUser() async {
    return await _db.getLoggedInUser();
  }

  // Login
  Future<AuthResult> login(String email, String password) async {
    try {
      final user = await _db.getUserByEmail(email.trim().toLowerCase());

      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      if (!user.verifyPassword(password)) {
        return AuthResult(
          success: false,
          message: 'Incorrect password',
        );
      }

      // Logout any other logged-in users
      await _db.logoutAllUsers();

      // Login this user
      user.isLoggedIn = true;
      user.lastLogin = DateTime.now();
      await _db.updateUser(user);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Sign up
  Future<AuthResult> signup(String name, String email, String password) async {
    try {
      // Check if email already exists
      final existingUser = await _db.getUserByEmail(email.trim().toLowerCase());
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }

      // Validate inputs
      if (name.trim().isEmpty) {
        return AuthResult(success: false, message: 'Please enter your name');
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        return AuthResult(success: false, message: 'Please enter a valid email');
      }
      if (password.length < 6) {
        return AuthResult(success: false, message: 'Password must be at least 6 characters');
      }

      // Logout any other users
      await _db.logoutAllUsers();

      // Create new user
      final user = AppUser(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: AppUser.hashPassword(password),
        isLoggedIn: true,
        lastLogin: DateTime.now(),
      );

      await _db.saveUser(user);

      return AuthResult(success: true, user: user, message: 'Account created successfully!');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Signup failed: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout(AppUser user) async {
    user.isLoggedIn = false;
    await _db.updateUser(user);
  }

  // Delete account
  Future<void> deleteAccount(AppUser user) async {
    // Delete user's transactions
    // (You'd need to add a userId field to transactions for this)
    await _db.isar.writeTxn(() async {
      await _db.isar.appUsers.delete(user.id);
    });
  }

  // Validate password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null; // Valid
  }

  // Validate email
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email';
    return null;
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final AppUser? user;

  AuthResult({required this.success, this.message, this.user});
}