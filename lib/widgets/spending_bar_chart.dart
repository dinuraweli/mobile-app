// File: lib/widgets/spending_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingBarChart extends StatelessWidget {
  final Map<String, double> dailySpending;
  final Color barColor;
  final bool showLabels;

  const SpendingBarChart({
    super.key,
    required this.dailySpending,
    this.barColor = const Color(0xFF66FCF1),
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpending.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No spending data', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    // Find max value for scaling
    final maxSpending = dailySpending.values.reduce((a, b) => a > b ? a : b);
    final entries = dailySpending.entries.toList();

    return Column(
      children: [
        // Chart area
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-axis labels
              _buildYAxis(maxSpending),
              const SizedBox(width: 8),
              // Bars
              ...entries.map((entry) => _buildBar(
                context, 
  label: entry.key,
  value: entry.value,
  maxValue: maxSpending,
  totalBars: entries.length,
)),
            ],
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 12),
          // Legend
          _buildLegend(entries, maxSpending),
        ],
      ],
    );
  }

  Widget _buildYAxis(double maxValue) {
    final steps = _generateSteps(maxValue);
    
    return SizedBox(
      width: 45,
      height: 175,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: steps.reversed.map((value) {
          return Text(
            NumberFormat.compact().format(value),
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<double> _generateSteps(double maxValue) {
    if (maxValue <= 0) return [0, 0, 0, 0];
    
    // Generate 4 nice steps
    double step = maxValue / 4;
    // Round up to nearest nice number
    double magnitude = 1;
    if (step >= 10000) magnitude = 5000;
    else if (step >= 5000) magnitude = 1000;
    else if (step >= 1000) magnitude = 500;
    else if (step >= 500) magnitude = 100;
    else if (step >= 100) magnitude = 50;
    else magnitude = 10;
    
    step = ((step / magnitude).ceil() * magnitude);
    if (step <= 0) step = magnitude;
    
    return [
      0,
      step,
      step * 2,
      step * 3,
      step * 4,
    ];
  }

 Widget _buildBar(
  BuildContext context, {  // ← ADD BuildContext
  required String label,
  required double value,
  required double maxValue,
  required int totalBars,
}) { 
    final height = maxValue > 0 ? (value / maxValue * 155).clamp(4.0, 155.0) : 4.0;
    final isHighest = value == maxValue && value > 0;
    
    // Calculate width based on number of bars
    final availableWidth = (MediaQuery.of(context).size.width - 85) / totalBars;
    final barWidth = (availableWidth * 0.6).clamp(8.0, 28.0);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: barWidth * 0.15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Amount label above bar
            if (isHighest)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(
                    color: barColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              height: height,
              width: barWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    barColor.withOpacity(isHighest ? 0.9 : 0.5),
                    barColor.withOpacity(isHighest ? 0.7 : 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Day label
            Text(
              label,
              style: TextStyle(
                color: isHighest ? Colors.white : Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: isHighest ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, double>> entries, double maxValue) {
    // Find interesting stats
    final highest = entries.reduce((a, b) => a.value > b.value ? a : b);
    final lowest = entries.where((e) => e.value > 0).toList();
    final lowestEntry = lowest.isNotEmpty 
        ? lowest.reduce((a, b) => a.value < b.value ? a : b) 
        : null;
    
    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    final average = entries.isNotEmpty ? total / entries.length : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Highest', highest.key, NumberFormat.compact().format(highest.value), barColor),
          if (lowestEntry != null)
            _buildStat('Lowest', lowestEntry.key, NumberFormat.compact().format(lowestEntry.value), const Color(0xFF4CAF50)),
          _buildStat('Average', '', NumberFormat.compact().format(average), const Color(0xFFFFA726)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String detail, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (detail.isNotEmpty)
          Text(
            detail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}