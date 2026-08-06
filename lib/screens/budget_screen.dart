import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  final int userId;

  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _db = DatabaseService();
  final _analytics = AnalyticsService();

  Map<String, Budget> _budgets = {};
  Map<String, double> _spending = {};
  bool _isLoading = true;

  static const _categories = [
    'Groceries', 'Transport', 'Dining', 'Bills & Utilities',
    'Recurring Payments', 'Shopping', 'Transfers', 'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.getBudgetsForUser(widget.userId),
      _analytics.getMonthlySummary(userId: widget.userId),
    ]);

    final budgetList = results[0] as List<Budget>;
    final summary = results[1] as MonthlySummary;

    if (mounted) {
      setState(() {
        _budgets = {for (var b in budgetList) b.category: b};
        _spending = summary.categoryTotals;
        _isLoading = false;
      });
    }
  }

  Color _catColor(String category) {
    switch (category) {
      case 'Groceries': return const Color(0xFF4CAF50);
      case 'Transport': return const Color(0xFF42A5F5);
      case 'Dining': return const Color(0xFFFFA726);
      case 'Bills & Utilities': return const Color(0xFFFFD54F);
      case 'Recurring Payments': return const Color(0xFF26A69A);
      case 'Shopping': return const Color(0xFFEC407A);
      case 'Transfers': return const Color(0xFF7E57C2);
      default: return const Color(0xFF78909C);
    }
  }

  IconData _catIcon(String category) {
    switch (category) {
      case 'Groceries': return Icons.shopping_cart_rounded;
      case 'Transport': return Icons.local_taxi_rounded;
      case 'Dining': return Icons.restaurant_rounded;
      case 'Bills & Utilities': return Icons.receipt_long_rounded;
      case 'Recurring Payments': return Icons.subscriptions_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Transfers': return Icons.swap_horiz_rounded;
      default: return Icons.category_rounded;
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    return 'LKR ${NumberFormat('#,##0').format(amount)}';
  }

  void _showBudgetDialog(String category) {
    final existing = _budgets[category];
    final controller = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1B1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_catIcon(category), color: _catColor(category), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Budget for $category',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                prefixText: 'LKR ',
                prefixStyle: TextStyle(color: Color(0xFF66FCF1), fontSize: 20),
                hintText: '0',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF66FCF1)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF66FCF1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (existing != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _db.deleteBudget(existing.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final val = double.tryParse(controller.text.trim());
                      if (val == null || val <= 0) return;
                      final Budget budget;
                      if (existing != null) {
                        existing.amount = val;
                        existing.updatedAt = DateTime.now();
                        budget = existing;
                      } else {
                        budget = Budget(
                          userId: widget.userId,
                          category: category,
                          amount: val,
                        );
                      }
                      await _db.saveBudget(budget);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66FCF1),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudgeted = _budgets.values.fold(0.0, (s, b) => s + b.amount);
    final totalSpent = _categories.fold(0.0, (s, c) => s + (_spending[c] ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Budgets', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B0C10),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
          : RefreshIndicator(
              color: const Color(0xFF66FCF1),
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(totalBudgeted, totalSpent),
                  const SizedBox(height: 20),
                  const Text(
                    'MONTHLY BUDGETS',
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  ..._categories.map((cat) => _buildCategoryRow(cat)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(double totalBudgeted, double totalSpent) {
    final hasAnyBudget = totalBudgeted > 0;
    final overBudget = hasAnyBudget && totalSpent > totalBudgeted;
    final progress = hasAnyBudget ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;

    Color progressColor = const Color(0xFF66FCF1);
    if (overBudget) {
      progressColor = Colors.redAccent;
    } else if (progress >= 0.9) {
      progressColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overBudget
              ? Colors.redAccent.withValues(alpha: 0.5)
              : const Color(0xFF66FCF1).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                    _fmt(totalSpent),
                    style: TextStyle(
                      color: overBudget ? Colors.redAccent : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Budgeted', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                    hasAnyBudget ? _fmt(totalBudgeted) : '—',
                    style: const TextStyle(
                      color: Color(0xFF66FCF1),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasAnyBudget) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overBudget
                  ? 'Over budget by ${_fmt(totalSpent - totalBudgeted)}'
                  : '${_fmt(totalBudgeted - totalSpent)} remaining',
              style: TextStyle(
                color: overBudget ? Colors.redAccent : Colors.white54,
                fontSize: 12,
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Tap a category below to set a budget',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category) {
    final budget = _budgets[category];
    final spent = _spending[category] ?? 0;
    final hasBudget = budget != null;
    final progress = hasBudget ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final overBudget = hasBudget && spent > budget.amount;
    final nearLimit = hasBudget && progress >= 0.7 && !overBudget;

    Color progressColor = const Color(0xFF66FCF1);
    if (overBudget) {
      progressColor = Colors.redAccent;
    } else if (nearLimit) {
      progressColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () => _showBudgetDialog(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: overBudget
                ? Colors.redAccent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _catColor(category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_catIcon(category), color: _catColor(category), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasBudget ? 'Budget: ${_fmt(budget.amount)}' : 'Tap to set budget',
                        style: TextStyle(
                          color: hasBudget
                              ? Colors.white54
                              : const Color(0xFF66FCF1).withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      spent > 0 ? _fmt(spent) : '—',
                      style: TextStyle(
                        color: overBudget ? Colors.redAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (hasBudget && spent > 0)
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: progressColor, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              if (overBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Over by ${_fmt(spent - budget.amount)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
