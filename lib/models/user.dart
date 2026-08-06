// File: lib/models/user.dart
import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class AppUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String email;

  late String name;
  late DateTime createdAt;
  DateTime? lastLogin;
  String? avatarPath;
  bool isBiometricEnabled = false;

  // Sri Lanka specific
  String? monthlySalary;
  String? employmentType; // private, government, self_employed
  String? tinNumber; // Tax Identification Number
  String? epfNumber;

  AppUser({
    this.id = Isar.autoIncrement,
    required this.email,
    required this.name,
    DateTime? createdAtValue,
    this.lastLogin,
    this.avatarPath,
    this.isBiometricEnabled = false,
    this.monthlySalary,
    this.employmentType,
    this.tinNumber,
    this.epfNumber,
  }) : createdAt = createdAtValue ?? DateTime.now();
}
