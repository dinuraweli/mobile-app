import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/balance_summary_card.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final int userId;
  final List<AppTransaction> transactions;
  final Map<String, String> customCategories;
  final VoidCallback onReset;
  final Function(AppTransaction) onAddNewTransaction;
  final Function(AppTransaction, AppTransaction) onEditTransaction;
  final bool isListeningSms;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    this.userName = 'User',
    required this.userId,
    required this.transactions,
    required this.onReset,
    required this.onAddNewTransaction,
    required this.onEditTransaction,
    required this.customCategories,
    this.isListeningSms = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Welcome, ${userName.split(' ')[0]}!'),
            const SizedBox(width: 8),
            if (isListeningSms)
              Tooltip(
                message: 'Auto-Sync Active',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onLogout,
              tooltip: 'Logout',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onReset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceSummaryCard(transactions: transactions),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(context, Icons.add_circle_outline, 'Add Entry', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(onTransactionExtracted: onAddNewTransaction, learningRules: customCategories, userId: userId)));
                  }),
                  _buildQuickAction(context, Icons.list_alt, 'History', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionHistoryScreen(transactions: transactions, onEdit: onEditTransaction)));
                  }),
                  _buildQuickAction(context, Icons.account_balance_wallet, 'Budgets', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(userId: userId)));
                  }),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text('No transactions yet. Click Quick Actions -> Add Entry to get started!')),
              ...transactions.take(5).map((t) => TransactionCard(transaction: t, onEdit: onEditTransaction)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
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