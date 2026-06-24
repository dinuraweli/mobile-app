import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final List<AppTransaction> transactions;
  final Function(AppTransaction, AppTransaction) onEdit;

  const TransactionHistoryScreen({super.key, required this.transactions, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions recorded.', style: TextStyle(fontSize: 16, color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) => TransactionCard(transaction: transactions[index], onEdit: onEdit),
            ),
    );
  }
}
