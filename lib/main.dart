import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:telephony/telephony.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const SalliMateApp());
}

// --- Data Models ---
class AppTransaction {
  final String id;
  final String bank;
  final double amount;
  final String merchant;
  final String type;
  final String date;
  final String category;
  final String accountType;
  final String accountMask;

  AppTransaction({
    String? id,
    required this.bank,
    required this.amount,
    required this.merchant,
    required this.type,
    required this.date,
    required this.category,
    this.accountType = 'Unknown',
    this.accountMask = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id, 'bank': bank, 'amount': amount, 'merchant': merchant,
        'type': type, 'date': date, 'category': category, 'accountType': accountType, 'accountMask': accountMask,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'], bank: json['bank'], amount: json['amount'], merchant: json['merchant'],
        type: json['type'], date: json['date'], category: json['category'],
        accountType: json['accountType'] ?? 'Unknown', accountMask: json['accountMask'] ?? '',
      );
}

class SalliMateApp extends StatelessWidget {
  const SalliMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalliMate Prototype',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007A76),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1F1F),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- Main Navigation Shell ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Telephony telephony = Telephony.instance;
  final String _apiKey = 'AIzaSyBYoNMqu743eIW6SeFTiAvk71pT9VH8Zps';

  Map<String, double> _bankBalances = {};
  List<AppTransaction> _transactions = [];
  Map<String, String> _customCategories = {}; 
  bool _isListeningToSms = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _initSmsListener();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTransactions = prefs.getString('transactions_data');
    final String? savedBalances = prefs.getString('balances_data');
    final String? savedRules = prefs.getString('learning_rules');

    setState(() {
      if (savedTransactions != null) {
        final List<dynamic> decodedList = jsonDecode(savedTransactions);
        _transactions = decodedList.map((item) => AppTransaction.fromJson(item)).toList();
      }
      if (savedBalances != null) {
        final Map<String, dynamic> decodedBalances = jsonDecode(savedBalances);
        _bankBalances = decodedBalances.map((key, value) => MapEntry(key, value as double));
      }
      if (savedRules != null) {
        final Map<String, dynamic> decodedRules = jsonDecode(savedRules);
        _customCategories = decodedRules.map((key, value) => MapEntry(key, value.toString()));
      }
    });
  }

  Future<void> _saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final txList = _transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString('transactions_data', jsonEncode(txList));
    await prefs.setString('balances_data', jsonEncode(_bankBalances));
    await prefs.setString('learning_rules', jsonEncode(_customCategories));
  }

  Future<void> _initSmsListener() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          if (message.body != null) _processIncomingSmsWithAI("Sender: ${message.address}\nMessage: ${message.body}");
        },
        listenInBackground: false, 
      );
      if (mounted) setState(() => _isListeningToSms = true);
    }
  }

  Future<void> _processIncomingSmsWithAI(String smsText) async {
    try {
      String rulesPrompt = _customCategories.isEmpty ? "" : 
          "\nUser's learned category preferences (use strictly if matched): ${jsonEncode(_customCategories)}";

      final systemInstruction = Content.system(
        'You are a financial data extraction bot. Analyze the SMS text and extract the information into a strict JSON object (NOT an array). '
        'Categorize food delivery like Uber Eats or PickMe Food strictly as "Food & Dining". '
        'Keys must exactly match: "bank", "amount" (number), "merchant", "category", "type" (Debit/Credit), "date" (string DD-MMM), '
        '"account_type" (Credit Card, Debit/Account, or Unknown), "account_mask". $rulesPrompt'
      );

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey, systemInstruction: systemInstruction, generationConfig: GenerationConfig(responseMimeType: 'application/json', temperature: 0.1));
      final response = await model.generateContent([Content.text(smsText)]);
      
      String rawText = response.text ?? '{}';
      final String tripleTicks = String.fromCharCode(96) * 3;
      rawText = rawText.replaceAll('$tripleTicks json', '').replaceAll(tripleTicks, '').trim();
      if (rawText.startsWith('[')) rawText = rawText.substring(1, rawText.length - 1).trim();
      int startIndex = rawText.indexOf('{'); int endIndex = rawText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) rawText = rawText.substring(startIndex, endIndex + 1); else throw FormatException('No JSON object found.');

      final parsedJson = jsonDecode(rawText);
      double extractedAmount = 0.0;
      if (parsedJson['amount'] != null) extractedAmount = double.tryParse(parsedJson['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final newTransaction = AppTransaction(
        bank: parsedJson['bank']?.toString() ?? 'Unknown', amount: extractedAmount, merchant: parsedJson['merchant']?.toString() ?? 'Unknown',
        type: parsedJson['type']?.toString() ?? 'Debit', date: parsedJson['date']?.toString() ?? 'Today',
        category: parsedJson['category']?.toString() ?? 'Other', accountType: parsedJson['account_type']?.toString() ?? 'Unknown', accountMask: parsedJson['account_mask']?.toString() ?? '',
      );
      
      if (!mounted) return;
      _addNewTransaction(newTransaction);
    } catch (e) {
      debugPrint('AI Parsing Error: $e');
    }
  }

  void _applyBalance(AppTransaction tx, Map<String, double> balances) {
    String maskText = tx.accountMask.isNotEmpty ? ' (**${tx.accountMask})' : '';
    String typeText = tx.accountType == 'Credit Card' ? 'Credit Card' : 'Account';
    String accountKey = '${tx.bank} $typeText$maskText'.trim();
    if (!balances.containsKey(accountKey)) balances[accountKey] = 0.0;
    balances[accountKey] = balances[accountKey]! + (tx.type.toLowerCase() == 'debit' ? -tx.amount : tx.amount);
  }

  void _revertBalance(AppTransaction tx, Map<String, double> balances) {
    String maskText = tx.accountMask.isNotEmpty ? ' (**${tx.accountMask})' : '';
    String typeText = tx.accountType == 'Credit Card' ? 'Credit Card' : 'Account';
    String accountKey = '${tx.bank} $typeText$maskText'.trim();
    if (!balances.containsKey(accountKey)) return;
    balances[accountKey] = balances[accountKey]! + (tx.type.toLowerCase() == 'debit' ? tx.amount : -tx.amount);
  }

  void _addNewTransaction(AppTransaction transaction) async {
    setState(() {
      _transactions = [transaction, ..._transactions];
      Map<String, double> newBalances = Map.from(_bankBalances);
      _applyBalance(transaction, newBalances);
      _bankBalances = newBalances;
    });
    await _saveDataLocally();
  }

  void _updateTransaction(AppTransaction oldTx, AppTransaction newTx) async {
    setState(() {
      int index = _transactions.indexWhere((t) => t.id == oldTx.id);
      if (index != -1) {
        Map<String, double> newBalances = Map.from(_bankBalances);
        _revertBalance(oldTx, newBalances);
        _transactions[index] = newTx;
        _applyBalance(newTx, newBalances);
        _bankBalances = newBalances;
        if (oldTx.category != newTx.category) {
          _customCategories[newTx.merchant.toUpperCase()] = newTx.category;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🧠 AI Learned: ${newTx.merchant} is now "${newTx.category}"'), backgroundColor: Colors.teal));
        }
      }
    });
    await _saveDataLocally();
  }

  void _resetData() async {
    setState(() { _transactions.clear(); _bankBalances.clear(); _customCategories.clear(); });
    await _saveDataLocally();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        HomeScreen(transactions: _transactions, bankBalances: _bankBalances, onReset: _resetData, onAddNewTransaction: _addNewTransaction, onEditTransaction: _updateTransaction, customCategories: _customCategories, isListeningSms: _isListeningToSms),
        const FinancialToolsScreen(),
        const LearningScreen(),
        const SalliBotScreen(),
      ][_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Learning'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'SalliBot'),
        ],
      ),
    );
  }
}

// --- Home Screen ---
class HomeScreen extends StatelessWidget {
  final List<AppTransaction> transactions;
  final Map<String, double> bankBalances;
  final Map<String, String> customCategories;
  final VoidCallback onReset;
  final Function(AppTransaction) onAddNewTransaction;
  final Function(AppTransaction, AppTransaction) onEditTransaction;
  final bool isListeningSms;

  const HomeScreen({super.key, required this.transactions, required this.bankBalances, required this.onReset, required this.onAddNewTransaction, required this.onEditTransaction, required this.customCategories, this.isListeningSms = false});

  void _showBankBalancesDialog(BuildContext context, double total) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Accounts & Cards'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [...bankBalances.entries.map((e) => _buildBankBalanceRow(e.key, e.value)), const Divider(thickness: 2), _buildBankBalanceRow('Total Net Worth', total, isTotal: true)])), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))]));
  }

  Widget _buildBankBalanceRow(String bank, double amount, {bool isTotal = false}) {
    bool isCreditCardOwed = bank.contains('Credit Card') && amount < 0;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(bank, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 13))), Text('LKR ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isCreditCardOwed ? Colors.orangeAccent : (amount < 0 ? Colors.redAccent : Colors.white)))]));
  }

  @override
  Widget build(BuildContext context) {
    double totalBalance = bankBalances.values.fold(0.0, (s, i) => s + i);
    double totalIncome = transactions.where((t) => t.type.toLowerCase() == 'credit').fold(0.0, (s, i) => s + i.amount);
    double totalExpense = transactions.where((t) => t.type.toLowerCase() == 'debit').fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Text('Welcome, Kasun!'), const SizedBox(width: 8), if (isListeningSms) Tooltip(message: 'Auto-Sync Active', child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)))]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { onReset(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data cleared!'))); })],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InsightsScreen(transactions: transactions))),
        icon: const Icon(Icons.auto_graph, color: Colors.black), label: const Text('Insights', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.tealAccent, elevation: 6,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showBankBalancesDialog(context, totalBalance),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF161919), Color(0xFF1E2424)], begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Total Net Worth', style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center), const SizedBox(height: 8),
                        Text('LKR ${totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8),
                        const Text('Tap to view accounts & cards', style: TextStyle(fontSize: 12, color: Colors.tealAccent), textAlign: TextAlign.center), const SizedBox(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildIncomeExpenseColumn('Income', 'LKR ${totalIncome.toStringAsFixed(0)}', Colors.greenAccent), Container(width: 1, height: 40, color: Colors.white10), _buildIncomeExpenseColumn('Expense', 'LKR ${totalExpense.toStringAsFixed(0)}', Colors.redAccent)]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildQuickAction(context, Icons.add_circle_outline, 'Add Entry', () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(onTransactionExtracted: onAddNewTransaction, learningRules: customCategories)))),
                _buildQuickAction(context, Icons.list_alt, 'History', () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(transactions: transactions, onEdit: onEditTransaction)))),
                _buildQuickAction(context, Icons.account_balance_wallet, 'Budgets', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')))),
              ]),
              const SizedBox(height: 32), const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
              if (transactions.isEmpty) const Padding(padding: EdgeInsets.all(16.0), child: Text('No transactions yet. Click Quick Actions -> Add Entry to get started!', style: TextStyle(color: Colors.white54))),
              ...transactions.take(5).map((t) => TransactionCard(transaction: t, onEdit: onEditTransaction)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseColumn(String label, String amount, Color color) => Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)), const SizedBox(height: 4), Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]);
  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) => Column(children: [CircleAvatar(radius: 28, backgroundColor: const Color(0xFF133634), child: IconButton(icon: Icon(icon, color: Colors.tealAccent), onPressed: onTap)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12))]);
}

// --- Common UI Components ---
class TransactionHistoryScreen extends StatelessWidget {
  final List<AppTransaction> transactions;
  final Function(AppTransaction, AppTransaction) onEdit;
  const TransactionHistoryScreen({super.key, required this.transactions, required this.onEdit});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Transaction History'), backgroundColor: Theme.of(context).colorScheme.inversePrimary), body: transactions.isEmpty ? const Center(child: Text('No transactions recorded.', style: TextStyle(fontSize: 16, color: Colors.white54))) : ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: transactions.length, itemBuilder: (context, index) => TransactionCard(transaction: transactions[index], onEdit: onEdit)));
}

class TransactionCard extends StatelessWidget {
  final AppTransaction transaction;
  final Function(AppTransaction, AppTransaction) onEdit;
  const TransactionCard({super.key, required this.transaction, required this.onEdit});

  void _showTransactionDetails(BuildContext context) {
    bool isDebit = transaction.type.toLowerCase() == 'debit';
    String maskText = transaction.accountMask.isNotEmpty ? '**${transaction.accountMask}' : 'N/A';
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 24), Center(child: Text(transaction.merchant, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), const SizedBox(height: 8), Center(child: Text('${isDebit ? '-' : '+'} LKR ${transaction.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : Colors.greenAccent))), const SizedBox(height: 24), const Divider(color: Colors.white10), const SizedBox(height: 16), _buildDetailRow('Date', transaction.date), _buildDetailRow('Category', transaction.category), _buildDetailRow('Bank', transaction.bank), _buildDetailRow('Account Type', transaction.accountType), if (transaction.accountMask.isNotEmpty) _buildDetailRow('Card/Account Number', maskText), _buildDetailRow('Transaction Type', transaction.type), const SizedBox(height: 32), SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.edit, color: Colors.white), label: const Text('Edit Transaction', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A76), padding: const EdgeInsets.all(16)), onPressed: () { Navigator.pop(context); _openEditDialog(context); })), const SizedBox(height: 24)])));
  }

  void _openEditDialog(BuildContext context) {
    final amtCtrl = TextEditingController(text: transaction.amount.toString());
    final merCtrl = TextEditingController(text: transaction.merchant);
    final catList = ['Food & Dining', 'Groceries', 'Transport', 'Utilities', 'Entertainment', 'Shopping', 'Subscriptions', 'Other'];
    String selCat = catList.contains(transaction.category) ? transaction.category : 'Other';
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Edit Transaction'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (LKR)'), keyboardType: TextInputType.number), const SizedBox(height: 12), TextField(controller: merCtrl, decoration: const InputDecoration(labelText: 'Merchant')), const SizedBox(height: 12), DropdownButtonFormField<String>(value: selCat, decoration: const InputDecoration(labelText: 'Category'), items: catList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => selCat = val!)])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { double newAmt = double.tryParse(amtCtrl.text) ?? transaction.amount; AppTransaction updated = AppTransaction(id: transaction.id, bank: transaction.bank, amount: newAmt, merchant: merCtrl.text, type: transaction.type, date: transaction.date, category: selCat, accountType: transaction.accountType, accountMask: transaction.accountMask); onEdit(transaction, updated); Navigator.pop(context); }, child: const Text('Save Changes'))]));
  }

  Widget _buildDetailRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));

  @override Widget build(BuildContext context) {
    IconData categoryIcon = Icons.receipt_long;
    if (transaction.category == 'Food & Dining') categoryIcon = Icons.fastfood;
    if (transaction.category == 'Groceries') categoryIcon = Icons.shopping_cart;
    if (transaction.category == 'Transport') categoryIcon = Icons.local_taxi;
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF161919), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _showTransactionDetails(context), child: ListTile(leading: Stack(alignment: Alignment.bottomRight, children: [CircleAvatar(backgroundColor: const Color(0xFF133634), child: Icon(categoryIcon, color: Colors.tealAccent)), Icon(transaction.accountType == 'Credit Card' ? Icons.credit_card : Icons.account_balance, size: 14, color: Colors.white)]), title: Text(transaction.merchant, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${transaction.date} • ${transaction.bank}${transaction.accountMask.isNotEmpty ? ' (**${transaction.accountMask})' : ''}', style: const TextStyle(fontSize: 12, color: Colors.white54)), trailing: Text('${transaction.type.toLowerCase() == 'debit' ? '-' : '+'} LKR ${transaction.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: transaction.type.toLowerCase() == 'debit' ? Colors.white : Colors.greenAccent, fontSize: 14)))));
  }
}

// --- Insights Screen (Abbreviated for space, assume fully intact from previous step) ---
class InsightsScreen extends StatefulWidget {
  final List<AppTransaction> transactions;
  const InsightsScreen({super.key, required this.transactions});
  @override State<InsightsScreen> createState() => _InsightsScreenState();
}
class _InsightsScreenState extends State<InsightsScreen> {
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Spending Insights'), backgroundColor: Theme.of(context).colorScheme.inversePrimary), body: const Center(child: Text("Insights Dashboard (Placeholder)", style: TextStyle(color: Colors.white54))));
}

// --- Unified Add Transaction Screen (Abbreviated for space) ---
class AddTransactionScreen extends StatefulWidget {
  final Function(AppTransaction) onTransactionExtracted;
  final Map<String, String> learningRules;
  const AddTransactionScreen({super.key, required this.onTransactionExtracted, required this.learningRules});
  @override State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}
class _AddTransactionScreenState extends State<AddTransactionScreen> {
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Add Transaction'), backgroundColor: Theme.of(context).colorScheme.inversePrimary), body: const Center(child: Text("Add Transaction UI (Placeholder)", style: TextStyle(color: Colors.white54))));
}


// --- 💰 NEW: FINANCIAL TOOLS SECTION 💰 ---

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Tools'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Calculators & Utilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _buildToolCard(
            context: context, 
            icon: Icons.calculate, 
            color: Colors.tealAccent, 
            title: 'APIT / PAYE Tax Calculator', 
            subtitle: 'Estimate your monthly corporate tax deductions.', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApitTaxCalculatorScreen()))
          ),
          const SizedBox(height: 12),
          
          _buildToolCard(context: context, icon: Icons.real_estate_agent, color: Colors.orangeAccent, title: 'Leasing Calculator', subtitle: 'Calculate monthly rentals for vehicles.', onTap: () {}),
          const SizedBox(height: 12),
          
          _buildToolCard(context: context, icon: Icons.account_balance, color: Colors.blueAccent, title: 'Fixed Deposit Returns', subtitle: 'Compare local bank FD rates and returns.', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildToolCard({required BuildContext context, required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161919), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 24, child: Icon(icon, color: color, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24)
            ],
          ),
        ),
      ),
    );
  }
}

// --- APIT / PAYE Tax Calculator Logic & UI ---
class ApitTaxCalculatorScreen extends StatefulWidget {
  const ApitTaxCalculatorScreen({super.key});

  @override
  State<ApitTaxCalculatorScreen> createState() => _ApitTaxCalculatorScreenState();
}

class _ApitTaxCalculatorScreenState extends State<ApitTaxCalculatorScreen> {
  final TextEditingController _salaryController = TextEditingController();
  
  double _grossSalary = 0.0;
  double _totalTax = 0.0;
  double _netSalary = 0.0;
  List<Map<String, dynamic>> _taxBreakdown = [];

  // Calculates tax based on official Sri Lankan Inland Revenue Dept (IRD) slabs
  void _calculateTax(String value) {
    setState(() {
      _grossSalary = double.tryParse(value) ?? 0.0;
      _totalTax = 0.0;
      _taxBreakdown.clear();

      if (_grossSalary <= 100000) {
        _netSalary = _grossSalary;
        return; 
      }

      double remainingTaxable = _grossSalary - 100000;
      const double slabLimit = 41666.67; 
      
      // Slabs and rates (Monthly)
      final List<double> rates = [0.06, 0.12, 0.18, 0.24, 0.30, 0.36];
      
      for (int i = 0; i < rates.length; i++) {
        if (remainingTaxable <= 0) break;

        double taxableInThisSlab = (remainingTaxable > slabLimit && i < 5) ? slabLimit : remainingTaxable;
        double taxForSlab = taxableInThisSlab * rates[i];
        
        _totalTax += taxForSlab;
        remainingTaxable -= taxableInThisSlab;

        _taxBreakdown.add({
          'rate': '${(rates[i] * 100).toInt()}%',
          'amount': taxForSlab,
        });
      }

      _netSalary = _grossSalary - _totalTax;
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('APIT / PAYE Calculator'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter Monthly Gross Salary', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _salaryController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _calculateTax,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'LKR ',
                prefixStyle: const TextStyle(fontSize: 24, color: Colors.tealAccent),
                filled: true, fillColor: const Color(0xFF161919),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            
            // Results Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF161919), Color(0xFF1E2424)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white.withOpacity(0.05))
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Net Take-Home Pay', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('LKR ${_netSalary.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Tax Deduction:', style: TextStyle(fontSize: 16, color: Colors.white70)),
                        Text('LKR ${_totalTax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            if (_taxBreakdown.isNotEmpty) ...[
              const Text('Tax Breakdown by Slabs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF161919), elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildBreakdownRow('First LKR 100,000 (Relief)', '0%', 0.0),
                      const Divider(color: Colors.white10),
                      ..._taxBreakdown.map((slab) => Column(
                        children: [
                          _buildBreakdownRow('Slab @ ${slab['rate']}', slab['rate'], slab['amount']),
                          if (slab != _taxBreakdown.last) const Divider(color: Colors.white10),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Text('Note: This calculator uses the latest IRD tax slabs. It assumes standard salaried employment without specific non-cash benefit exemptions.', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String rate, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text('LKR ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Placeholder Screens ---
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Learning Hub')));
}

class SalliBotScreen extends StatelessWidget {
  const SalliBotScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('SalliBot AI')));
}