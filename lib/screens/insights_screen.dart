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
    'Groceries': Colors.greenAccent,
    'Transport': Colors.blueAccent,
    'Dining': Colors.orangeAccent,
    'Bills & Utilities': Colors.yellowAccent,
    'Recurring Payments': Colors.tealAccent, // Replaced Subscriptions
    'Shopping': Colors.pinkAccent,
    'Transfers': Colors.purpleAccent,
    'Income': Colors.lightGreenAccent,
    'General': Colors.grey, // Replaced Other
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
    if (category == 'Recurring Payments') return true; // Updated here
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
                if (highestSub != null && lowestSub != null)
                  Row(
                    children: [
                      Expanded(child: _buildSmallStatCard('Highest Sub', highestSub.merchant, 'LKR ${highestSub.amount.toStringAsFixed(0)}', Colors.redAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallStatCard('Lowest Sub', lowestSub.merchant, 'LKR ${lowestSub.amount.toStringAsFixed(0)}', Colors.greenAccent)),
                    ],
                  ),
                // Smart Coaching Nudges
                const SizedBox(height: 12),
                ..._generateSmartCoaching(filteredTx).map((nudge) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.tealAccent.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(children: [
                      const Icon(Icons.lightbulb, color: Colors.tealAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(nudge, style: const TextStyle(fontSize: 13, color: Colors.white))),
                    ]),
                  ),
                )),
              ],
              const SizedBox(height: 24),

              // 3. STACKED SCREEN TIME CHART
              const Text('Daily Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildStackedBarChart(dailyCategoryTotals),
              // Daily Reflections
              if (dailyCategoryTotals.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._generateReflections(dailyCategoryTotals.map((date, cats) => MapEntry(date, cats.values.fold(0, (sum, val) => sum + val)))).map((reflection) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.purpleAccent.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(children: [
                      const Icon(Icons.analytics, color: Colors.purpleAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(reflection, style: const TextStyle(fontSize: 13, color: Colors.white))),
                    ]),
                  ),
                )),
              ],
              const SizedBox(height: 32),

              // 4. CATEGORY DONUT CHART
              const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (sortedCategoryPercentages.isEmpty) const Text('Not enough data.', style: TextStyle(color: Colors.white54))
              else Center(child: _buildDonutChart(sortedCategoryPercentages)),
              const SizedBox(height: 32),

              // 5. SUBSCRIPTIONS LIST
              if (uniqueSubscriptions.isNotEmpty) ...[
                const Text('Active Recurring Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Changed title here
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

  // --- STACKED BAR CHART (7-DAY WEEK VIEW) ---
  Widget _buildStackedBarChart(Map<String, Map<String, double>> dailyData) {
    if (dailyData.isEmpty) return const SizedBox(height: 150, child: Center(child: Text('No chart data')));

    // 1. Group data strictly into a 7-day list (Mon -> Sun)
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // 2. Parse dates and determine the current week's Monday
    var dates = dailyData.keys.toList();
    dates.sort((a, b) => _parseDateStr(a).compareTo(_parseDateStr(b)));

    DateTime? firstDate = dates.isNotEmpty ? _parseDateStr(dates.first) : null;
    DateTime weekStart = firstDate ?? DateTime.now();
    
    // Calculate Monday of the week containing the first transaction
    int daysToMonday = (weekStart.weekday - 1) % 7;
    weekStart = weekStart.subtract(Duration(days: daysToMonday));

    // 3. Build a 7-day map
    Map<int, Map<String, double>> weekData = {};
    for (int i = 0; i < 7; i++) {
      weekData[i] = {};
    }

    // 4. Populate the week data
    for (String date in dates) {
      DateTime dateObj = _parseDateStr(date);
      int daysFromMonday = (dateObj.difference(weekStart).inDays) % 7;
      
      if (daysFromMonday >= 0 && daysFromMonday < 7) {
        Map<String, double> categoriesForDay = dailyData[date]!;
        categoriesForDay.forEach((category, amount) {
          weekData[daysFromMonday]![category] = (weekData[daysFromMonday]![category] ?? 0) + amount;
        });
      }
    }

    // 5. Find max weekly total for scaling
    double maxWeeklyTotal = 0;
    Set<String> usedCategories = {};
    for (int i = 0; i < 7; i++) {
      double dayTotal = weekData[i]!.values.fold(0, (a, b) => a + b);
      if (dayTotal > maxWeeklyTotal) maxWeeklyTotal = dayTotal;
      weekData[i]!.forEach((cat, _) => usedCategories.add(cat));
    }
    if (maxWeeklyTotal == 0) maxWeeklyTotal = 1;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Chart Area
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  double dailyTotal = weekData[index]!.values.fold(0, (a, b) => a + b);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: 'LKR ${dailyTotal.toStringAsFixed(0)}',
                        preferBelow: false,
                        verticalOffset: 10,
                        child: _buildDayBar(dailyTotal, maxWeeklyTotal, weekData[index]!),
                      ),
                      const SizedBox(height: 8),
                      Text(days[index], style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                    ],
                  );
                }),
              ),
            ),
          ),
          // Legend Area
          if (usedCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: usedCategories.map((cat) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _categoryColors[cat] ?? _categoryColors['General'], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text(cat, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayBar(double dailyTotal, double maxWeeklyTotal, Map<String, double> categories) {
    const double trackHeight = 150.0;
    double heightRatio = maxWeeklyTotal > 0 ? (dailyTotal / maxWeeklyTotal) : 0;
    double fillHeight = trackHeight * heightRatio;

    return Container(
      height: trackHeight,
      width: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: fillHeight,
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: categories.entries.map((cat) {
              return Container(
                height: fillHeight > 0 ? fillHeight * (cat.value / dailyTotal) : 0,
                color: _categoryColors[cat.key],
              );
            }).toList(),
          ),
        ),
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
            Color color = _categoryColors[e.key] ?? _categoryColors['General']!;
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

  List<String> _generateSmartCoaching(List<AppTransaction> txs) {
    List<String> nudges = [];
    DateTime now = DateTime.now();

    // Salary Week Check
    if (now.day >= 25 || now.day <= 5) {
      nudges.add("It's salary week! Are we saving or spending?");
    }
    
    // Credit Card Check
    bool hasCreditCard = txs.any((t) => t.accountType == 'Credit Card');
    if (hasCreditCard && now.day > 20) {
      nudges.add("Don't postpone paying your credit card. Avoid extra charges by paying early.");
    }

    // Subscription Check
    double subTotal = txs.where((t) => t.category == 'Recurring Payments').fold(0, (sum, t) => sum + t.amount);
    if (subTotal > 0) {
      nudges.add("Your subscription payments are coming up. You spent LKR ${subTotal.toStringAsFixed(0)} on them recently.");
    }

    if (nudges.isEmpty) nudges.add("Quick tip: Tracking daily helps you save 20% more monthly!");
    return nudges;
  }

  List<String> _generateReflections(Map<String, double> dailyTotals) {
    List<String> reflections = [];
    
    if (dailyTotals.isNotEmpty) {
      var sortedDays = dailyTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      var highestDay = sortedDays.first;
      var lowestDay = sortedDays.last;

      reflections.add("Your expenses peaked on ${highestDay.key} at LKR ${highestDay.value.toStringAsFixed(0)}.");
      if (lowestDay.value > 0) {
        reflections.add("Great job on ${lowestDay.key}! You kept spending down to LKR ${lowestDay.value.toStringAsFixed(0)}.");
      }
    }
    return reflections;
  }
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
      paint.color = colorMap[key] ?? colorMap['General']!;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}