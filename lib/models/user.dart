// File: lib/models/user.dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class AppUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String email;

  late String name;
  late String passwordHash; // In production, use proper hashing
  late DateTime createdAt;
  DateTime? lastLogin;
  String? avatarPath;
  bool isBiometricEnabled = false;
  bool isLoggedIn = false;

  // Sri Lanka specific
  String? monthlySalary;
  String? employmentType; // private, government, self_employed
  String? tinNumber; // Tax Identification Number
  String? epfNumber;

  AppUser({
    this.id = Isar.autoIncrement,
    required this.email,
    required this.name,
    required this.passwordHash,
    DateTime? createdAtValue,
    this.lastLogin,
    this.avatarPath,
    this.isBiometricEnabled = false,
    this.isLoggedIn = false,
    this.monthlySalary,
    this.employmentType,
    this.tinNumber,
    this.epfNumber,
  }) : createdAt = createdAtValue ?? DateTime.now();

  // Simple password hashing (use proper crypto in production!)
  static String hashPassword(String password) {
    // This is a simple hash - use bcrypt/scrypt in production
    return '${password.split('').reversed.join()}_sallimate_hash';
  }

  bool verifyPassword(String password) {
    return passwordHash == hashPassword(password);
  }
}