// File: lib/services/database_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  late Isar isar;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [AppTransactionSchema, AppUserSchema],
      directory: dir.path,
      inspector: true,
    );
    _initialized = true;
    print('✅ Database initialized successfully');
  }
  
  Future<int> saveTransaction(AppTransaction transaction) async {
    return await isar.writeTxn(() async {
      return await isar.appTransactions.put(transaction);
    });
  }
  
  Future<List<AppTransaction>> getAllTransactions() async {
    return await isar.appTransactions
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  Future<void> updateTransaction(AppTransaction transaction) async {
    await isar.writeTxn(() async {
      await isar.appTransactions.put(transaction);
    });
  }
  
  Future<bool> deleteTransaction(int id) async {
    return await isar.writeTxn(() async {
      return await isar.appTransactions.delete(id);
    });
  }
  
  Future<void> clearAllTransactions() async {
    await isar.writeTxn(() async {
      await isar.appTransactions.clear();
    });
  }

  // ==================== USER OPERATIONS ====================

  Future<int> saveUser(AppUser user) async {
    return await isar.writeTxn(() async {
      return await isar.appUsers.put(user);
    });
  }

  Future<AppUser?> getUserByEmail(String email) async {
    return await isar.appUsers
        .filter()
        .emailEqualTo(email.toLowerCase().trim())
        .findFirst();
  }

  Future<AppUser?> getLoggedInUser() async {
    return await isar.appUsers
        .filter()
        .isLoggedInEqualTo(true)
        .findFirst();
  }

  Future<List<AppUser>> getAllUsers() async {
    return await isar.appUsers.where().findAll();
  }

  Future<void> logoutAllUsers() async {
    final users = await isar.appUsers.filter().isLoggedInEqualTo(true).findAll();
    for (var user in users) {
      user.isLoggedIn = false;
    }
    await isar.writeTxn(() async {
      await isar.appUsers.putAll(users);
    });
  }

  Future<void> updateUser(AppUser user) async {
    await isar.writeTxn(() async {
      await isar.appUsers.put(user);
    });
  }
  
  // FIXED: Properly sum the amounts
  Future<double> getTotalExpenses() async {
    final transactions = await isar.appTransactions
        .filter()
        .typeEqualTo('debit')
        .findAll();
    
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }
  
  // FIXED: Properly sum the amounts
  Future<double> getTotalIncome() async {
    final transactions = await isar.appTransactions
        .filter()
        .typeEqualTo('credit')
        .findAll();
    
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }
  
  Future<int> getTransactionCount() async {
    return await isar.appTransactions.count();
  }
  
  Future<void> close() async {
    await isar.close();
  }
}