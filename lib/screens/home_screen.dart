import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';
import 'insights_screen.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<AppTransaction> transactions;
  final Map<String, String> customCategories;
  final VoidCallback onReset;
  final Function(AppTransaction) onAddNewTransaction;
  final Function(AppTransaction, AppTransaction) onEditTransaction;
  final bool isListeningSms;

  const HomeScreen({
    super.key, 
    required this.transactions, 
    required this.onReset, 
    required this.onAddNewTransaction, 
    required this.onEditTransaction, 
    required this.customCategories,
    this.isListeningSms = false,
  });

  void _showBankBalancesDialog(BuildContext context, Map<String, double> balances, double total) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tracked Accounts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (balances.isEmpty)
                  const Text('No transactions recorded yet.', style: TextStyle(color: Colors.white54)),
                ...balances.entries.map((e) => _buildBankBalanceRow(e.key, e.value)),
                const Divider(thickness: 2),
                _buildBankBalanceRow('Total Net Tracked', total, isTotal: true),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
        );
      },
    );
  }

  Widget _buildBankBalanceRow(String bank, double amount, {bool isTotal = false}) {
    bool isCreditCardOwed = bank.contains('Credit Card') && amount < 0;
    final formattedAmount = NumberFormat('#,##0.00').format(amount);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(bank, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 13))),
          Text('LKR $formattedAmount', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isCreditCardOwed ? Colors.orangeAccent : (amount < 0 ? Colors.redAccent : Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate dynamic bank balances based ONLY on transactions
    Map<String, double> dynamicBankBalances = {};
    for (var t in transactions) {
      if (!dynamicBankBalances.containsKey(t.bank)) {
        dynamicBankBalances[t.bank] = 0.0;
      }
      if (t.type.toLowerCase() == 'credit') {
        dynamicBankBalances[t.bank] = dynamicBankBalances[t.bank]! + t.amount;
      } else {
        dynamicBankBalances[t.bank] = dynamicBankBalances[t.bank]! - t.amount;
      }
    }

    double totalBalance = dynamicBankBalances.values.fold(0.0, (sum, item) => sum + item);
    double totalIncome = transactions.where((t) => t.type.toLowerCase() == 'credit').fold(0.0, (sum, item) => sum + item.amount);
    double totalExpense = transactions.where((t) => t.type.toLowerCase() == 'debit').fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Welcome, Kasun!'),
            const SizedBox(width: 8),
            if (isListeningSms) Tooltip(message: 'Auto-Sync Active', child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)))
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { onReset(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data cleared!'))); })],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InsightsScreen(transactions: transactions))),
        icon: const Icon(Icons.auto_graph, color: Color(0xFF0B0C10)),
        label: const Text('Insights', style: TextStyle(color: Color(0xFF0B0C10), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF66FCF1), elevation: 8,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showBankBalancesDialog(context, dynamicBankBalances, totalBalance),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF45A29E), Color(0xFF1F2833)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF66FCF1).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('TOTAL TRACKED BALANCE', style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 1.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('LKR ${NumberFormat('#,##0.00').format(totalBalance)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text('Tap to view tracked accounts & cards', style: TextStyle(fontSize: 12, color: Color(0xFF66FCF1)), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIncomeExpenseColumn('Income', 'LKR ${NumberFormat('#,##0').format(totalIncome)}', const Color(0xFF66FCF1)),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _buildIncomeExpenseColumn('Expense', 'LKR ${NumberFormat('#,##0').format(totalExpense)}', Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(context, Icons.add_circle_outline, 'Add Entry', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(onTransactionExtracted: onAddNewTransaction, learningRules: customCategories)));
                  }),
                  _buildQuickAction(context, Icons.list_alt, 'History', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(transactions: transactions, onEdit: onEditTransaction)));
                  }),
                  _buildQuickAction(context, Icons.account_balance_wallet, 'Budgets', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')))),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text('No transactions yet. Click Quick Actions -> Add Entry to get started!')),
              ...transactions.take(5).map((t) => TransactionCard(transaction: t, onEdit: onEditTransaction)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseColumn(String label, String amount, Color color) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)), const SizedBox(height: 4), Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]);
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2833),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: const Color(0xFF66FCF1), size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}