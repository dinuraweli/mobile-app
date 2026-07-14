// File: lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/transaction_parser.dart';
import '../utils/sms_validator.dart';
import '../widgets/floating_nav_bar.dart';

import 'home_screen.dart';
import 'insights_screen.dart';
import 'financial_tools_screen.dart';
import 'learning_screen.dart';
import 'sallibot_screen.dart';

class MainNavigation extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final Telephony telephony = Telephony.instance;

  List<AppTransaction> _transactions = [];
  final Map<String, String> _customCategories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initSmsListener();
    _checkPendingSms();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await DatabaseService().getTransactionsByUserId(widget.currentUser.id);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading transactions: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTransactionToDb(AppTransaction transaction) async {
    try {
      await DatabaseService().saveTransaction(transaction);
    } catch (e) {
      debugPrint("Error saving transaction: $e");
    }
  }

  void _initSmsListener() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          String sender = message.address ?? '';
          String body = message.body ?? '';

          if (SmsValidator.isBankTransaction(sender, body)) {
            _processTransactionSMS(body);
          }
        },
        listenInBackground: false,
      );
    }
  }

  Future<void> _checkPendingSms() async {
    if (!Hive.isBoxOpen('pending_sms')) {
      await Hive.openBox<String>('pending_sms');
    }

    var box = Hive.box<String>('pending_sms');

    if (box.isEmpty) return;

    for (int i = 0; i < box.length; i++) {
      String? rawSms = box.getAt(i);
      if (rawSms != null && rawSms.isNotEmpty) {
        await _processTransactionSMS(rawSms);
      }
    }

    await box.clear();
  }

  Future<void> _processTransactionSMS(String smsBody) async {
    final transaction = await TransactionParser.parse(smsBody, userId: widget.currentUser.id);

    if (transaction != null && transaction.amount > 0) {
      _handleNewTransaction(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ LKR ${transaction.amount.toStringAsFixed(0)} at ${transaction.merchant}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleNewTransaction(AppTransaction transaction) {
    _saveTransactionToDb(transaction);
    setState(() {
      _transactions.insert(0, transaction);
    });
  }

  void _handleEditTransaction(AppTransaction oldTx, AppTransaction newTx) async {
    await DatabaseService().updateTransaction(newTx);
    setState(() {
      final index = _transactions.indexWhere((t) => t.transactionId == oldTx.transactionId);
      if (index != -1) {
        _transactions[index] = newTx;
      }
    });
  }

  void _handleReset() async {
    await DatabaseService().clearAllTransactions(userId: widget.currentUser.id);
    setState(() {
      _transactions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0C10),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF66FCF1)),
              const SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0B0C10),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            userName: widget.currentUser.name,
            userId: widget.currentUser.id,
            transactions: _transactions,
            customCategories: _customCategories,
            onReset: _handleReset,
            onAddNewTransaction: _handleNewTransaction,
            onEditTransaction: _handleEditTransaction,
            isListeningSms: true,
            onLogout: widget.onLogout,
          ),
          InsightsScreen(transactions: _transactions),
          const FinancialToolsScreen(),
          const LearningScreen(),
          const SalliBotScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}