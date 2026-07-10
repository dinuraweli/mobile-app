// File: lib/services/database_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

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
      [AppTransactionSchema],
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