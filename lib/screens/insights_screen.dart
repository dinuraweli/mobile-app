import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class InsightsScreen extends StatefulWidget {
  final List<AppTransaction> transactions;

  const InsightsScreen({super.key, required this.transactions});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedFilter = 'Monthly';
  final List<String> _filters = ['Weekly', 'Monthly'];
  
  // Changed to late so we can initialize it to the actual current month
  late String _selectedMonth; 
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  late String _selectedWeek; 
  List<String> _weeklyRanges = [];

  // Consistent Category Colors for Stacked Chart and Donut
  final Map<String, Color> _categoryColors = {
    'Food & Dining': Colors.orangeAccent,
    'Groceries': Colors.greenAccent,
    'Transport': Colors.blueAccent,
    'Utilities': Colors.yellowAccent,
    'Entertainment': Colors.purpleAccent,
    'Shopping': Colors.pinkAccent,
    'Subscriptions': Colors.tealAccent,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    // 1. Initialize the month first
    _selectedMonth = DateFormat('MMM').format(DateTime.now());
    
    // 2. Generate the ranges and set the initial value for _selectedWeek
    // We don't read _selectedWeek here, we just assign it.
    _generateWeeklyRanges(_selectedMonth);
  }

  DateTime _parseDateStr(String dateStr) {
    if (dateStr.toLowerCase() == 'today') return DateTime.now();
    if (dateStr.toLowerCase() == 'yesterday') return DateTime.now().subtract(const Duration(days: 1));
    try { return DateFormat('dd-MMM').parse(dateStr); } catch (e) {
      try { return DateFormat('d-MMM').parse(dateStr); } catch (e2) { return DateTime.fromMillisecondsSinceEpoch(0); }
    }
  }

  void _generateWeeklyRanges(String month) {
    _weeklyRanges = [
      '$month 04 - $month 10', 
      '$month 11 - $month 17',
      '$month 18 - $month 24', 
      '$month 25 - $month 31',
    ];
    
    // FIX: Assign directly without reading the previous value of _selectedWeek
    _selectedWeek = _weeklyRanges[0];
  }

  bool _isSubscription(String merchant, String category) {
    if (category == 'Subscriptions') return true;
    final keywords = ['netflix', 'spotify', 'dialog', 'slt', 'mobitel', 'peo tv', 'pickme pass', 'daraz club', 'apple', 'google', 'zoom', 'canva'];
    return keywords.any((k) => merchant.toLowerCase().contains(k));
  }

  @override
  Widget build(BuildContext context) {
    // FIXED FILTERING LOGIC: We convert "Today" into its actual month dynamically
    List<AppTransaction> filteredTx = widget.transactions.where((t) {
      DateTime txDate = _parseDateStr(t.date);
      String txMonth = DateFormat('MMM').format(txDate);
      
      if (_selectedFilter == 'Monthly' || _selectedFilter == 'Weekly') {
        return txMonth == _selectedMonth;
      }
      return true;
    }).toList();

    // --- Analytics Processing ---
    Map<String, Map<String, double>> dailyCategoryTotals = {};
    Map<String, double> vendorTotals = {};
    Map<String, double> categoryTotals = {};
    // Subscriptions grouping
    Map<String, AppTransaction> uniqueSubscriptions = {};
    double grandTotalExpense = 0;

    for (var t in filteredTx) {
      if (t.type.toLowerCase() == 'debit') {
        
        // NORMALIZATION FIX: Convert "Today" to formatted date so bars group correctly
        DateTime dateObj = _parseDateStr(t.date);
        String normalizedDate = DateFormat('dd-MMM').format(dateObj);

        // Daily Chart Data
        if (!dailyCategoryTotals.containsKey(normalizedDate)) dailyCategoryTotals[normalizedDate] = {};
        dailyCategoryTotals[normalizedDate]![t.category] = (dailyCategoryTotals[normalizedDate]![t.category] ?? 0) + t.amount;
        
        // Vendor/Category Data
        vendorTotals[t.merchant] = (vendorTotals[t.merchant] ?? 0) + t.amount;
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
        grandTotalExpense += t.amount;

        // Subs Data
        if (_isSubscription(t.merchant, t.category)) {
          if (!uniqueSubscriptions.containsKey(t.merchant) || uniqueSubscriptions[t.merchant]!.amount < t.amount) {
            uniqueSubscriptions[t.merchant] = t;
          }
        }
      }
    }

    var sortedVendors = vendorTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String highestVendor = sortedVendors.isNotEmpty ? sortedVendors.first.key : 'None';

    AppTransaction? highestSub;
    AppTransaction? lowestSub;
    if (uniqueSubscriptions.isNotEmpty) {
      var sortedSubs = uniqueSubscriptions.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
      highestSub = sortedSubs.first;
      lowestSub = sortedSubs.last;
    }

    Map<String, double> categoryPercentages = {};
    if (grandTotalExpense > 0) {
      categoryTotals.forEach((k, v) => categoryPercentages[k] = v / grandTotalExpense);
    }
    var sortedCategoryPercentages = Map.fromEntries(categoryPercentages.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Insights'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP LEVEL FILTERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: _filters.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter), selected: _selectedFilter == filter,
                        onSelected: (selected) { if (selected) setState(() => _selectedFilter = filter); },
                        selectedColor: Colors.teal.withValues(alpha: 0.4),
                      ),
                    )).toList(),
                  ),
                  if (_selectedFilter == 'Monthly')
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth, icon: const Icon(Icons.calendar_month, color: Colors.tealAccent),
                        items: _months.map((m) => DropdownMenuItem(value: m, child: Text(' $m '))).toList(),
                        onChanged: (val) { setState(() { _selectedMonth = val!; _generateWeeklyRanges(val); }); },
                      ),
                    ),
                ],
              ),
              if (_selectedFilter == 'Weekly')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedWeek, icon: const Icon(Icons.date_range, color: Colors.tealAccent),
                      items: _weeklyRanges.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) => setState(() => _selectedWeek = val!),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 2. SPENDING PATTERNS (TOP LEVEL)
              const Text('Spending Patterns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (filteredTx.isEmpty) const Text('No data for selected period.', style: TextStyle(color: Colors.white54))
              else ...[
                _buildPatternInsightCard(icon: Icons.trending_up, iconColor: Colors.orangeAccent, title: 'Top Vendor: $highestVendor', subtitle: 'You spent the most here this period.'),
                if (highestSub != null)
                  Row(
                    children: [
                      Expanded(child: _buildSmallStatCard('Highest Sub', highestSub.merchant, 'LKR ${highestSub.amount.toStringAsFixed(0)}', Colors.redAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallStatCard('Lowest Sub', lowestSub!.merchant, 'LKR ${lowestSub!.amount.toStringAsFixed(0)}', Colors.greenAccent)),
                    ],
                  ),
              ],
              const SizedBox(height: 24),

              // 3. STACKED SCREEN TIME CHART
              const Text('Daily Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildStackedBarChart(dailyCategoryTotals),
              const SizedBox(height: 32),

              // 4. CATEGORY DONUT CHART
              const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (sortedCategoryPercentages.isEmpty) const Text('Not enough data.', style: TextStyle(color: Colors.white54))
              else Center(child: _buildDonutChart(sortedCategoryPercentages)),
              const SizedBox(height: 32),

              // 5. SUBSCRIPTIONS LIST
              if (uniqueSubscriptions.isNotEmpty) ...[
                const Text('Active Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: uniqueSubscriptions.length, separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (c, i) {
                      final sub = uniqueSubscriptions.values.elementAt(i);
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.autorenew, color: Colors.blueAccent)),
                        title: Text(sub.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Last paid: ${sub.date}', style: const TextStyle(fontSize: 12)),
                        trailing: Text('LKR ${sub.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- STACKED BAR CHART (SCREEN TIME STYLE) ---
  Widget _buildStackedBarChart(Map<String, Map<String, double>> dailyData) {
    if (dailyData.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('No chart data')));

    // 1. Chronological Sorting
    var dates = dailyData.keys.toList();
    dates.sort((a, b) => _parseDateStr(a).compareTo(_parseDateStr(b)));

    // 2. Find Max and Average Daily Totals
    double maxDaily = 0;
    double totalSum = 0;
    for (String date in dates) {
      double dailyTotal = dailyData[date]!.values.fold(0, (a, b) => a + b);
      if (dailyTotal > maxDaily) maxDaily = dailyTotal;
      totalSum += dailyTotal;
    }
    if (maxDaily == 0) maxDaily = 1;
    double avgDaily = dates.isNotEmpty ? totalSum / dates.length : 0;
    double avgRatio = avgDaily / maxDaily;

    // We keep track of which categories are actually used to build the legend
    Set<String> usedCategories = {};

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Chart Area
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                // Average Dashed Line
                if (avgDaily > 0)
                  Positioned(
                    bottom: 24 + (130 * avgRatio), 
                    left: 0, right: 0,
                    child: CustomPaint(painter: DashedLinePainter()),
                  ),
                // Horizontal Scroll for Bars
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // Right aligned
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dates.map((date) {
                        Map<String, double> categoriesForDay = dailyData[date]!;
                        double dailyTotal = categoriesForDay.values.fold(0, (a, b) => a + b);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: 'LKR ${dailyTotal.toStringAsFixed(0)}',
                                preferBelow: false, verticalOffset: 10,
                                child: Container(
                                  width: 24,
                                  height: 130, // Fixed track height
                                  alignment: Alignment.bottomCenter,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: categoriesForDay.entries.map((entry) {
                                      usedCategories.add(entry.key);
                                      double hRatio = entry.value / maxDaily;
                                      return Container(
                                        width: 24,
                                        height: 130 * hRatio,
                                        color: _categoryColors[entry.key] ?? _categoryColors['Other'],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(date.replaceAll('-', '\n'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Legend Area
          if (usedCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
              child: Wrap(
                spacing: 12, runSpacing: 8,
                alignment: WrapAlignment.center,
                children: usedCategories.map((cat) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _categoryColors[cat] ?? _categoryColors['Other'], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text(cat, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                )).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 140, height: 140,
          child: CustomPaint(
            painter: DonutChartPainter(data, _categoryColors), 
            child: const Center(child: Icon(Icons.pie_chart, color: Colors.white24, size: 40))
          )
        ),
        const SizedBox(width: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((e) {
            Color color = _categoryColors[e.key] ?? _categoryColors['Other']!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), 
                const SizedBox(width: 8), 
                Text('${e.key} (${(e.value * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12))
              ]),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatternInsightCard({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: CircleAvatar(backgroundColor: iconColor.withValues(alpha: 0.2), child: Icon(icon, color: iconColor)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70))));
  }

  Widget _buildSmallStatCard(String title, String day, String amount, Color amountColor) {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)), const SizedBox(height: 4), Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 16))])));
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5, startX = 0;
    final paint = Paint()..color = Colors.green.withValues(alpha: 0.7)..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colorMap;
  DonutChartPainter(this.data, this.colorMap);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    double startAngle = -3.141592653589793 / 2; 
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt;
    data.forEach((key, value) {
      final sweepAngle = (value * 2 * 3.141592653589793);
      paint.color = colorMap[key] ?? colorMap['Other']!;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}