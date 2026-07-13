// File: lib/widgets/balance_summary_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class BalanceSummaryCard extends StatelessWidget {
  final List<AppTransaction> transactions;

  const BalanceSummaryCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final accountBalances = _calculateAccountBalances();
    final totalIncome = _calculateTotal(accountBalances, isIncome: true);
    final totalExpense = _calculateTotal(accountBalances, isIncome: false);
    final netBalance = totalIncome - totalExpense;

    return GestureDetector(
      onTap: () => _showDetailedBreakdown(context, accountBalances, netBalance),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF66FCF1).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF66FCF1).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66FCF1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap for details',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF66FCF1),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF66FCF1)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Net Balance
              Text(
                'LKR ${NumberFormat('#,##0.00').format(netBalance)}',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: netBalance >= 0 ? Colors.white : Colors.redAccent,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),

              // Income & Expense Summary
              Row(
                children: [
                  _buildSummaryPill(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Income',
                    amount: totalIncome,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryPill(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Expenses',
                    amount: totalExpense,
                    color: const Color(0xFFEF5350),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini account indicator
              if (accountBalances.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, 
                               size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      '${accountBalances.length} ${accountBalances.length == 1 ? 'account' : 'accounts'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                    const Spacer(),
                    // Show dots for each account
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: accountBalances.keys.take(4).map((account) {
                        final accountData = accountBalances[account];
                        final balance = (accountData?['balance'] as double?) ?? 0.0;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: balance < 0
                                ? Colors.redAccent.withOpacity(0.6)
                                : const Color(0xFF66FCF1).withOpacity(0.6),
                          ),
                        );
                      }).toList(),
                    ),
                    if (accountBalances.length > 4)
                      Text(
                        ' +${accountBalances.length - 4}',
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormat.compact().format(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateAccountBalances() {
    final Map<String, Map<String, dynamic>> accounts = {};

    for (var t in transactions) {
      final key = _getAccountKey(t);
      
      if (!accounts.containsKey(key)) {
        accounts[key] = {
          'balance': 0.0,
          'income': 0.0,
          'expense': 0.0,
          'bank': t.bank,
          'accountMask': t.accountMask,
          'accountType': t.accountType,
        };
      }

      if (t.isCredit) {
        accounts[key]!['balance'] = (accounts[key]!['balance'] as double) + t.amount;
        accounts[key]!['income'] = (accounts[key]!['income'] as double) + t.amount;
      } else {
        accounts[key]!['balance'] = (accounts[key]!['balance'] as double) - t.amount;
        accounts[key]!['expense'] = (accounts[key]!['expense'] as double) + t.amount;
      }
    }

    return accounts;
  }

  String _getAccountKey(AppTransaction t) {
    // Group by bank + account mask
    final bank = t.bankShortName;
    final mask = t.accountMask.isNotEmpty ? t.accountMask : 
                 (t.accountType == 'Credit Card' ? 'Credit' : 'Other');
    return '$bank-$mask';
  }

  double _calculateTotal(Map<String, Map<String, dynamic>> accounts, {required bool isIncome}) {
    double total = 0;
    for (var account in accounts.values) {
      if (isIncome) {
        total += account['income'] as double;
      } else {
        total += account['expense'] as double;
      }
    }
    return total;
  }

  void _showDetailedBreakdown(
    BuildContext context,
    Map<String, Map<String, dynamic>> accountBalances,
    double netBalance,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Row(
                    children: [
                      const Icon(Icons.account_balance, color: Color(0xFF66FCF1), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Account Breakdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: netBalance >= 0 
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : const Color(0xFFEF5350).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LKR ${NumberFormat('#,##0.00').format(netBalance)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0 
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFEF5350),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ...(() {
                          final sortedEntries = accountBalances.entries.toList()
                            ..sort((a, b) => (b.value['balance'] as double)
                                .compareTo(a.value['balance'] as double));

                          return sortedEntries.map((entry) {
                            final balance = entry.value['balance'] as double;
                            final income = entry.value['income'] as double;
                            final expense = entry.value['expense'] as double;
                            final bank = entry.value['bank'] as String;
                            final mask = entry.value['accountMask'] as String;
                            final type = entry.value['accountType'] as String;

                            return _buildAccountTile(
                              bank: bank,
                              mask: mask,
                              type: type,
                              balance: balance,
                              income: income,
                              expense: expense,
                            );
                          }).toList();
                        })(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAccountTile({
    required String bank,
    required String mask,
    required String type,
    required double balance,
    required double income,
    required double expense,
  }) {
    final isCreditCard = type.toLowerCase().contains('credit');
    final isPositive = balance >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Bank icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF66FCF1).withOpacity(0.2),
                      const Color(0xFF45A29E).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    bank.length > 3 ? bank.substring(0, 3).toUpperCase() : bank.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF66FCF1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Account info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatBankName(bank),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mask.isNotEmpty 
                          ? '•••• $mask ${isCreditCard ? '(Credit)' : ''}'
                          : type,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${NumberFormat('#,##0.00').format(balance.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isPositive 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPositive ? 'Balance' : 'Owed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Income/Expense breakdown
          if (income > 0 || expense > 0) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (income > 0)
                  _buildMiniStat(
                    label: 'In',
                    amount: income,
                    color: const Color(0xFF4CAF50),
                  ),
                if (income > 0 && expense > 0) 
                  const SizedBox(width: 16),
                if (expense > 0)
                  _buildMiniStat(
                    label: 'Out',
                    amount: expense,
                    color: const Color(0xFFEF5350),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${NumberFormat.compact().format(amount)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatBankName(String bank) {
    final lower = bank.toLowerCase();
    if (lower.contains('commercial') || lower.contains('combank')) return 'Commercial Bank';
    if (lower.contains('sampath')) return 'Sampath Bank';
    if (lower.contains('hnb')) return 'HNB';
    if (lower.contains('boc')) return 'Bank of Ceylon';
    if (lower.contains('ndb')) return 'NDB';
    if (lower.contains('seylan')) return 'Seylan Bank';
    if (lower.contains('ntb')) return 'Nations Trust Bank';
    if (lower.contains('hsbc')) return 'HSBC';
    return bank;
  }
}