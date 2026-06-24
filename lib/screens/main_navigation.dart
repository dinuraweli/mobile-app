import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Import your existing models and utilities
import '../models/transaction.dart';
import '../utils/sms_validator.dart';

// Import your screens
import 'home_screen.dart';
import 'financial_tools_screen.dart'; 
import 'learning_screen.dart'; 
import 'sallibot_screen.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final Telephony telephony = Telephony.instance;
  
  // The global transaction list
  List<AppTransaction> _transactions = []; 
  
  // NOTE: The hardcoded _bankBalances map has been removed!

  // IMPORTANT: Replace with your actual API key securely before production
  static const String _geminiApiKey = 'AIzaSyAbC5HMYjlfpaKlgAnmlKMrldMfvcSwKgA'; 

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  void _initSmsListener() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          String sender = message.address ?? '';
          String body = message.body ?? '';

          if (SmsValidator.isBankTransaction(sender, body)) {
            debugPrint("Valid bank SMS detected from $sender. Sending to Gemini...");
            _extractTransactionWithGemini(body);
          } else {
            debugPrint("Ignored non-transactional or promotional SMS from $sender.");
          }
        },
        listenInBackground: false, 
      );
    }
  }

  Future<void> _extractTransactionWithGemini(String smsBody) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // Updated to match your latest preference
        apiKey: _geminiApiKey,
        systemInstruction: Content.system(SmsValidator.geminiSystemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json', 
        ),
      );

      final prompt = 'Extract the transaction details from this SMS: "$smsBody"';
      final response = await model.generateContent([Content.text(prompt)]);
      final String rawJson = response.text ?? '{}';
      final Map<String, dynamic> data = jsonDecode(rawJson);

      if (data.containsKey('error')) {
        debugPrint("Gemini Failsafe Triggered: ${data['error']} - SMS: $smsBody");
        return; 
      }

      final newTransaction = AppTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bank: data['bank']?.toString() ?? 'Unknown Bank',
        amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
        merchant: data['merchant']?.toString() ?? 'Unknown',
        type: data['type']?.toString() ?? 'Debit',
        date: "Today", 
        category: data['category']?.toString() ?? 'Other',
        accountType: 'Account',
        accountMask: data['accountMask']?.toString() ?? '',
      );

      if (newTransaction.amount > 0) {
        _handleNewTransaction(newTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged LKR ${newTransaction.amount} at ${newTransaction.merchant}'), backgroundColor: Colors.green),
          );
        }
      }

    } catch (e) {
      debugPrint("Error extracting transaction: $e");
    }
  }

  void _handleNewTransaction(AppTransaction transaction) {
    setState(() {
      _transactions.insert(0, transaction);
    });
  }

  void _handleEditTransaction(AppTransaction oldTx, AppTransaction newTx) {
    setState(() {
      final index = _transactions.indexOf(oldTx);
      if (index != -1) {
        _transactions[index] = newTx;
      }
    });
  }

  void _handleReset() {
    setState(() {
      _transactions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            transactions: _transactions,
            // We no longer pass bankBalances from here. The Home screen calculates it dynamically.
            customCategories: const {},
            onReset: _handleReset,
            onAddNewTransaction: _handleNewTransaction,
            onEditTransaction: _handleEditTransaction,
            isListeningSms: true,
          ),
          const FinancialToolsScreen(),
          const LearningScreen(),
          const SalliBotScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0C10),
        selectedItemColor: const Color(0xFF66FCF1),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'SalliBot'),
        ],
      ),
    );
  }
}