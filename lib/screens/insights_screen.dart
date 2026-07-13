// File: lib/screens/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/analytics_service.dart';

class InsightsScreen extends StatefulWidget {
  final List<AppTransaction> transactions;

  const InsightsScreen({super.key, required this.transactions});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  MonthlySummary? _summary;
  SpendingPrediction? _prediction;
  List<SmartInsight> _insights = [];
  bool _isLoading = true;
  String? _searchQuery;
  String _selectedFilter = 'All';
  String _selectedMonth = '';

  final List<String> _filters = ['All', 'Income', 'Expenses'];
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMM').format(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final month = _months.indexOf(_selectedMonth) + 1;
      final summary = await _analytics.getMonthlySummary(month: month);
      final prediction = await _analytics.predictMonthlySpending();
      final insights = await _analytics.generateInsights();

      setState(() {
        _summary = summary;
        _prediction = prediction;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<AppTransaction> get _filteredTransactions {
    var list = widget.transactions;

    // Filter by search
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      list = list.where((t) =>
        t.merchant.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
        t.category.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
        t.amount.toString().contains(_searchQuery!)
      ).toList();
    }

    // Filter by type
    if (_selectedFilter == 'Income') {
      list = list.where((t) => t.isCredit).toList();
    } else if (_selectedFilter == 'Expenses') {
      list = list.where((t) => t.isDebit).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF66FCF1)))
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader()),
                  
                  // Monthly Summary Cards
                  SliverToBoxAdapter(child: _buildMonthlySummaryCards()),
                  
                  // Smart Insights
                  if (_insights.isNotEmpty)
                    SliverToBoxAdapter(child: _buildSmartInsights()),
                  
                  // Spending Trend Chart
                  if (_prediction != null)
                    SliverToBoxAdapter(child: _buildTrendChart()),
                  
                  // Category Breakdown
                  if (_summary != null)
                    SliverToBoxAdapter(child: _buildCategoryBreakdown()),
                  
                  // Search & Filter
                  SliverToBoxAdapter(child: _buildSearchAndFilter()),
                  
                  // Transaction List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTransactionTile(_filteredTransactions[index]),
                      childCount: _filteredTransactions.length,
                    ),
                  ),
                  
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Insights',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Month selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF66FCF1), size: 20),
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Color(0xFF66FCF1), fontWeight: FontWeight.w600),
                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedMonth = val!);
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_summary != null)
            Text(
              '${_summary!.transactionCount} transactions this month',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCards() {
    if (_summary == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryCard(
                title: 'Income',
                amount: _summary!.totalIncome,
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                title: 'Expenses',
                amount: _summary!.totalExpenses,
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFEF5350),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard(
                title: 'Savings',
                amount: _summary!.netSavings,
                icon: Icons.savings_rounded,
                color: const Color(0xFF66FCF1),
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                title: 'Avg Daily',
                amount: _summary!.averageDailySpend,
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFFFA726),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LKR ${NumberFormat.compact().format(amount)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ..._insights.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: insight.type == InsightType.warning
                    ? Colors.orange.withOpacity(0.3)
                    : insight.type == InsightType.positive
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: insight.type == InsightType.warning
                        ? Colors.orange.withOpacity(0.1)
                        : insight.type == InsightType.positive
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFF66FCF1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(insight.icon, size: 22, color: const Color(0xFF66FCF1)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(insight.description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_prediction == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spending Trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    painter: TrendChartPainter(_prediction!.monthlyTrends),
                    size: const Size(double.infinity, 160),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _prediction!.message,
                  style: TextStyle(
                    color: _prediction!.trend == 'up' ? Colors.orange : const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_summary == null || _summary!.sortedCategories.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: _summary!.sortedCategories.take(5).map((cat) {
                double percentage = _summary!.categoryPercentages[cat.key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.key, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getCategoryColor(cat.key),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: const Color(0xFF1A1A2E),
                    selectedColor: const Color(0xFF66FCF1).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF66FCF1),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF66FCF1) : Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(AppTransaction transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.merchant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${transaction.date} • ${transaction.category}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isDebit ? '-' : '+'} LKR ${NumberFormat('#,##0').format(transaction.amount)}',
            style: TextStyle(
              color: transaction.isDebit ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries': return Colors.green;
      case 'Transport': return Colors.blue;
      case 'Dining': return Colors.orange;
      case 'Bills & Utilities': return Colors.yellow;
      case 'Recurring Payments': return Colors.teal;
      case 'Shopping': return Colors.pink;
      case 'Transfers': return Colors.purple;
      case 'Income': return const Color(0xFF4CAF50);
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries': return Icons.shopping_cart_rounded;
      case 'Transport': return Icons.local_taxi_rounded;
      case 'Dining': return Icons.restaurant_rounded;
      case 'Bills & Utilities': return Icons.receipt_long_rounded;
      case 'Recurring Payments': return Icons.repeat_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Transfers': return Icons.swap_horiz_rounded;
      case 'Income': return Icons.account_balance_wallet_rounded;
      default: return Icons.category_rounded;
    }
  }
}

// ==================== TREND CHART PAINTER ====================

class TrendChartPainter extends CustomPainter {
  final List<MonthlyTrend> trends;

  TrendChartPainter(this.trends);

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final maxY = trends.map((t) => t.totalExpenses).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;
    final range = maxY - minY;

    final stepX = size.width / (trends.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < trends.length; i++) {
      final x = i * stepX;
      final y = size.height - ((trends[i].totalExpenses - minY) / range * (size.height - 20) + 10);
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF66FCF1).withOpacity(0.3),
        const Color(0xFF66FCF1).withOpacity(0.0),
      ],
    );
    canvas.drawPath(fillPath, Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Draw line
    paint.shader = const LinearGradient(
      colors: [Color(0xFF66FCF1), Color(0xFF45A29E)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots
    for (var point in points) {
      dotPaint.color = const Color(0xFF66FCF1);
      canvas.drawCircle(point, 4, dotPaint);
      dotPaint.color = Colors.white;
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}