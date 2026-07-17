// File: lib/widgets/spending_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingBarChart extends StatelessWidget {
  final Map<String, double> dailySpending;

  const SpendingBarChart({super.key, required this.dailySpending});

  @override
  Widget build(BuildContext context) {
    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final orderedData = <String, double>{};
    for (var day in allDays) {
      orderedData[day] = dailySpending[day] ?? 0.0;
    }

    final maxSpending = orderedData.values.reduce((a, b) => a > b ? a : b);
    final total = orderedData.values.fold(0.0, (sum, v) => sum + v);
    final average = total / 7;
    
    final highestEntry = orderedData.entries.reduce((a, b) => a.value > b.value ? a : b);
    final nonZero = orderedData.entries.where((e) => e.value > 0).toList();
    final lowestEntry = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a.value < b.value ? a : b)
        : null;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildYAxis(maxSpending),
              const SizedBox(width: 4),
              ...orderedData.entries.map((e) => _buildBar(context, e.key, e.value, maxSpending)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Highest', highestEntry.key, _fmt(highestEntry.value), const Color(0xFF66FCF1)),
              if (lowestEntry != null)
                _buildStat('Lowest', lowestEntry.key, _fmt(lowestEntry.value), const Color(0xFF4CAF50)),
              _buildStat('Avg/Day', '', _fmt(average), const Color(0xFFFFA726)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYAxis(double maxValue) {
    final steps = _niceSteps(maxValue);
    return SizedBox(
      width: 42,
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: steps.reversed.map((v) => Text(
          NumberFormat.compact().format(v),
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9, fontWeight: FontWeight.w500),
        )).toList(),
      ),
    );
  }

  List<double> _niceSteps(double max) {
    if (max <= 0) return [0, 250, 500, 750, 1000];
    double step = max / 4;
    double mag = 1;
    if (step >= 10000) mag = 5000;
    else if (step >= 5000) mag = 1000;
    else if (step >= 1000) mag = 500;
    else if (step >= 500) mag = 100;
    else if (step >= 100) mag = 50;
    else mag = 10;
    step = ((step / mag).ceil() * mag);
    if (step <= 0) step = mag;
    return [0, step, step * 2, step * 3, step * 4];
  }

  Widget _buildBar(BuildContext context, String label, double value, double maxValue) {
  final barMaxH = 110.0;
  final height = maxValue > 0 ? (value / maxValue * barMaxH).clamp(0.0, barMaxH) : 0.0;
  final isHighest = value > 0 && value == maxValue;
  final hasValue = value > 0;
  final screenW = MediaQuery.of(context).size.width;
  final barW = ((screenW - 80) / 7 * 0.5).clamp(12.0, 32.0);

  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Amount label above highest bar
        if (isHighest)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              _fmt(value),
              style: const TextStyle(color: Color(0xFF66FCF1), fontSize: 9, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
        // Bar
        Container(
          height: hasValue ? height : 3,
          width: barW,
          decoration: BoxDecoration(
            color: hasValue ? const Color(0xFF66FCF1).withOpacity(isHighest ? 0.9 : 0.45) : Colors.white.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        // Day label
        Text(
          label,
          style: TextStyle(
            color: isHighest ? Colors.white : Colors.white.withOpacity(0.35),
            fontSize: 10,
            fontWeight: isHighest ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStat(String label, String detail, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        if (detail.isNotEmpty)
          Text(detail, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9)),
      ],
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return NumberFormat('#,##0').format(amount);
    return amount.toStringAsFixed(0);
  }
}