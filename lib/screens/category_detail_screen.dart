// File: lib/screens/category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/analytics_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  final String displayName;
  final int userId;
  final int month;
  final int year;
  final Color color;
  final IconData icon;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.displayName,
    required this.userId,
    required this.month,
    required this.year,
    required this.color,
    required this.icon,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  List<AppTransaction> _transactions = [];
  double _total = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _transactions = await _analytics.getTransactionsByCategory(
        userId: widget.userId,
        category: widget.category,
        month: widget.month,
        year: widget.year,
      );
      _total = _transactions.where((t) => t.isDebit).fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      debugPrint('Error loading category: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  IconData _getIcon(String category) {
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

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(DateTime(widget.year, widget.month));
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: Text(widget.displayName),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
          : _transactions.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white.withValues(alpha:0.1)),
                    const SizedBox(height: 16),
                    Text('No ${widget.displayName} transactions', style: const TextStyle(color: Colors.white38, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('for $monthName ${widget.year}', style: const TextStyle(color: Colors.white24, fontSize: 14)),
                  ]),
                )
              : Column(
                  children: [
                    // Summary header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha:0.08),
                        border: Border(bottom: BorderSide(color: widget.color.withValues(alpha:0.2))),
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: widget.color.withValues(alpha:0.1), shape: BoxShape.circle),
                          child: Icon(widget.icon, color: widget.color, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LKR ${NumberFormat('#,##0.00').format(_total)}',
                          style: TextStyle(color: widget.color, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'} in $monthName',
                          style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 13),
                        ),
                      ]),
                    ),
                    // Transaction list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final t = _transactions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(color: widget.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(_getIcon(t.category), color: widget.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.merchant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(t.createdAt),
                                    style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 11),
                                  ),
                                ]),
                              ),
                              Text(
                                'LKR ${NumberFormat('#,##0.00').format(t.amount)}',
                                style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}