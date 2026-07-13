import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final AppTransaction transaction;
  final Function(AppTransaction, AppTransaction) onEdit;

  const TransactionCard({super.key, required this.transaction, required this.onEdit});

  void _showTransactionDetails(BuildContext context) {
    bool isDebit = transaction.type.toLowerCase() == 'debit';
    String maskText = transaction.accountMask.isNotEmpty ? '**${transaction.accountMask}' : 'N/A';
    
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2833),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Center(child: Text(transaction.merchant, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Center(child: Text('${isDebit ? '-' : '+'} LKR ${NumberFormat('#,##0.00').format(transaction.amount)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDebit ? Colors.white : const Color(0xFF66FCF1)))),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              _buildDetailRow('Date', transaction.date),
              _buildDetailRow('Category', transaction.category),
              _buildDetailRow('Bank', transaction.bank),
              _buildDetailRow('Account Type', transaction.accountType),
              if (transaction.accountMask.isNotEmpty) _buildDetailRow('Card/Account Number', maskText),
              _buildDetailRow('Transaction Type', transaction.type),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, color: Color(0xFF0B0C10)),
                  label: const Text('Edit Transaction', style: TextStyle(color: Color(0xFF0B0C10), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF66FCF1), padding: const EdgeInsets.all(16)),
                  onPressed: () {
                    Navigator.pop(context);
                    _openEditDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  void _openEditDialog(BuildContext context) {
    final amtCtrl = TextEditingController(text: transaction.amount.toString());
    final merCtrl = TextEditingController(text: transaction.merchant);
    // Ensure these exactly match what we will tell the Gemini API to use!
    final catList = [
      'Groceries', 'Transport', 'Dining', 'Bills & Utilities', 
      'Recurring Payments', 'Shopping', 'Transfers', 'Income', 'General'
    ];
    String selCat = catList.contains(transaction.category) ? transaction.category : 'Other';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount (LKR)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: merCtrl, decoration: const InputDecoration(labelText: 'Merchant')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: catList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => selCat = val!,
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                double newAmt = double.tryParse(amtCtrl.text) ?? transaction.amount;
                AppTransaction updated = AppTransaction.create(
  bank: transaction.bank,
  bankName: transaction.bankName,
  amount: newAmt,
  merchant: merCtrl.text,
  type: transaction.type,
  date: transaction.date,
  category: selCat,
  accountType: transaction.accountType,
  accountMask: transaction.accountMask,
  availableBalance: transaction.availableBalance,
  source: transaction.source,
);
                onEdit(transaction, updated);
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            )
          ],
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData categoryIcon = Icons.receipt_long;
    
    // Map the new strict AI categories to Material Icons
    switch (transaction.category) {
      case 'Groceries': categoryIcon = Icons.shopping_cart; break;
      case 'Transport': categoryIcon = Icons.local_taxi; break;
      case 'Dining': categoryIcon = Icons.fastfood; break;
      case 'Bills & Utilities': categoryIcon = Icons.bolt; break;
      case 'Recurring Payments': categoryIcon = Icons.autorenew; break; // Replaced Subscriptions
      case 'Shopping': categoryIcon = Icons.shopping_bag; break;
      case 'Transfers': categoryIcon = Icons.swap_horiz; break;
      case 'Income': categoryIcon = Icons.account_balance_wallet; break;
      case 'General': default: categoryIcon = Icons.category; break;
    }

    String accString = transaction.accountMask.isNotEmpty ? ' (**${transaction.accountMask})' : '';

    // ... rest of your build method remains exactly the same!

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showTransactionDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2833),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF66FCF1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: const Color(0xFF66FCF1), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${transaction.date} • ${transaction.bankDisplay}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              Text(
                '${transaction.type.toLowerCase() == 'debit' ? '-' : '+'} LKR ${NumberFormat('#,##0').format(transaction.amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: transaction.type.toLowerCase() == 'debit' ? Colors.white : const Color(0xFF66FCF1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}