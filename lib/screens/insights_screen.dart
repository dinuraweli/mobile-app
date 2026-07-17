// File: lib/screens/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/analytics_service.dart';
import '../widgets/spending_bar_chart.dart';
import '../widgets/top_merchants_widget.dart';

class InsightsScreen extends StatefulWidget {
  final List<AppTransaction> transactions;
  final int userId;

  const InsightsScreen({super.key, required this.transactions, required this.userId});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  MonthlySummary? _summary;
  SpendingPrediction? _prediction;
  List<SmartInsight> _insights = [];
  bool _isLoading = true;
  String _selectedMonth = '';
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMM').format(DateTime.now());
    _loadData();
  }

  @override
  void didUpdateWidget(InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions.length != widget.transactions.length) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final month = _months.indexOf(_selectedMonth) + 1;
      final results = await Future.wait([
        _analytics.getMonthlySummary(userId: widget.userId, month: month),
        _analytics.predictMonthlySpending(userId: widget.userId),
        _analytics.generateInsights(userId: widget.userId),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as MonthlySummary;
          _prediction = results[1] as SpendingPrediction;
          _insights = results[2] as List<SmartInsight>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    return 'LKR ${NumberFormat('#,##0').format(amount)}';
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
      case 'Income': return const Color(0xFF4CAF50);
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
      case 'Income': return Icons.account_balance_wallet_rounded;
      default: return Icons.category_rounded;
    }
  }

  String _catDisplay(String category) {
    return category == 'Recurring Payments' ? 'Subscriptions' : category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
            : RefreshIndicator(
                color: const Color(0xFF66FCF1),
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    if (_summary != null && _summary!.transactionCount > 0) ...[
                      SliverToBoxAdapter(child: _buildSummaryCards()),
                      SliverToBoxAdapter(child: _buildDailyChart()),
                      SliverToBoxAdapter(child: _buildTopMerchants()),
                      SliverToBoxAdapter(child: _buildCategories()),
                      if (_insights.isNotEmpty) SliverToBoxAdapter(child: _buildInsights()),
                      if (_summary!.subscriptions.isNotEmpty) SliverToBoxAdapter(child: _buildSubscriptions()),
                    ] else
                      SliverToBoxAdapter(child: _buildEmptyState()),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Financial Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF66FCF1), size: 20),
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.w600),
                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) { setState(() => _selectedMonth = val!); _loadData(); },
                ),
              ),
            ),
          ]),
          if (_summary != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${_summary!.transactionCount} transactions', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final s = _summary!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(children: [
          _card('Income', _fmt(s.totalIncome), const Color(0xFF4CAF50), Icons.arrow_downward_rounded),
          const SizedBox(width: 12),
          _card('Expenses', _fmt(s.totalExpenses), const Color(0xFFEF5350), Icons.arrow_upward_rounded),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _card('Savings', _fmt(s.netSavings), const Color(0xFF66FCF1), Icons.savings_rounded),
          const SizedBox(width: 12),
          _card('Avg/Day', _fmt(s.averageDailySpend), const Color(0xFFFFA726), Icons.calendar_today_rounded),
        ]),
      ]),
    );
  }

  Widget _card(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildDailyChart() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Daily Spending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF66FCF1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_summary!.month, style: TextStyle(color: const Color(0xFF66FCF1).withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: SpendingBarChart(dailySpending: _summary!.dailyTotals),
        ),
      ]),
    );
  }

  Widget _buildTopMerchants() {
    if (_summary!.sortedVendors.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: TopMerchantsWidget(merchants: _summary!.sortedVendors, totalSpending: _summary!.totalExpenses),
    );
  }

  Widget _buildCategories() {
    if (_summary!.sortedCategories.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Category Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            children: _summary!.sortedCategories.take(5).map((cat) {
              double pct = _summary!.categoryPercentages[cat.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Icon(_catIcon(cat.key), size: 18, color: _catColor(cat.key)),
                      const SizedBox(width: 8),
                      Text(_catDisplay(cat.key), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                    Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.white.withOpacity(0.04), valueColor: AlwaysStoppedAnimation<Color>(_catColor(cat.key)), minHeight: 6),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildInsights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Smart Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ..._insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: insight.type == InsightType.warning ? Colors.orange.withOpacity(0.2) : insight.type == InsightType.positive ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF66FCF1).withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(insight.icon, size: 20, color: const Color(0xFF66FCF1))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 2),
              Text(insight.description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ])),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSubscriptions() {
    final grouped = <String, double>{};
    for (var sub in _summary!.subscriptions) {
      grouped[sub.merchant] = sub.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Active Subscriptions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            children: grouped.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFF26A69A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.subscriptions_rounded, color: Color(0xFF26A69A), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                Text('LKR ${NumberFormat('#,##0').format(e.value)}', style: const TextStyle(color: Color(0xFF26A69A), fontWeight: FontWeight.bold)),
              ]),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white12),
        const SizedBox(height: 16),
        const Text('No transactions yet', style: TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Add transactions to see insights for $_selectedMonth', style: const TextStyle(color: Colors.white24, fontSize: 14)),
      ]),
    );
  }
}