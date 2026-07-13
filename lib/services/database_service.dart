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
  
  // ==================== TRANSACTION OPERATIONS ====================
  
  Future<int> saveTransaction(AppTransaction transaction) async {
    return await isar.writeTxn(() async {
      return await isar.appTransactions.put(transaction);
    });
  }
  
  // FIXED: Proper Isar query syntax
  Future<List<AppTransaction>> getAllTransactions({int? userId}) async {
    if (userId != null) {
      return await isar.appTransactions
          .filter()
          .userIdEqualTo(userId)
          .sortByCreatedAtDesc()
          .findAll();
    } else {
      return await isar.appTransactions
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    }
  }
  
  Future<List<AppTransaction>> getTransactionsByUserId(int userId) async {
    return await isar.appTransactions
        .filter()
        .userIdEqualTo(userId)
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
  
  Future<void> clearAllTransactions({int? userId}) async {
    await isar.writeTxn(() async {
      if (userId != null) {
        final userTxns = await isar.appTransactions
            .filter()
            .userIdEqualTo(userId)
            .findAll();
        final ids = userTxns.map((t) => t.id).toList();
        await isar.appTransactions.deleteAll(ids);
      } else {
        await isar.appTransactions.clear();
      }
    });
  }
  
  // FIXED: Query syntax
  Future<double> getTotalExpenses({int? userId}) async {
    List<AppTransaction> transactions;
    
    if (userId != null) {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('debit')
          .and()
          .userIdEqualTo(userId)
          .findAll();
    } else {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('debit')
          .findAll();
    }
    
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }
  
  Future<double> getTotalIncome({int? userId}) async {
    List<AppTransaction> transactions;
    
    if (userId != null) {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('credit')
          .and()
          .userIdEqualTo(userId)
          .findAll();
    } else {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('credit')
          .findAll();
    }
    
    double total = 0.0;
    for (var t in transactions) {
      total += t.amount;
    }
    return total;
  }
  
  Future<Map<String, double>> getCategoryTotals({int? userId}) async {
    List<AppTransaction> transactions;
    
    if (userId != null) {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('debit')
          .and()
          .userIdEqualTo(userId)
          .findAll();
    } else {
      transactions = await isar.appTransactions
          .filter()
          .typeEqualTo('debit')
          .findAll();
    }
    
    final Map<String, double> totals = {};
    for (var t in transactions) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }
  
  Future<Map<String, double>> getBankBalances({int? userId}) async {
    List<AppTransaction> transactions;
    
    if (userId != null) {
      transactions = await isar.appTransactions
          .filter()
          .userIdEqualTo(userId)
          .findAll();
    } else {
      transactions = await isar.appTransactions.where().findAll();
    }
    
    final Map<String, double> balances = {};
    for (var t in transactions) {
      balances[t.bank] = (balances[t.bank] ?? 0);
      if (t.isCredit) {
        balances[t.bank] = balances[t.bank]! + t.amount;
      } else {
        balances[t.bank] = balances[t.bank]! - t.amount;
      }
    }
    return balances;
  }
  
  Future<int> getTransactionCount({int? userId}) async {
    if (userId != null) {
      return await isar.appTransactions
          .filter()
          .userIdEqualTo(userId)
          .count();
    }
    return await isar.appTransactions.count();
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
  
  Future<void> close() async {
    await isar.close();
  }
}