// File: lib/services/analytics_service.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'database_service.dart';

class AnalyticsService {
  final DatabaseService _db = DatabaseService();

  // ==================== MONTHLY SUMMARIES ====================

  Future<MonthlySummary> getMonthlySummary({required int userId, int? month, int? year}) async {
    month ??= DateTime.now().month;
    year ??= DateTime.now().year;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Get only this user's transactions
    final allTransactions = await _db.getTransactionsByUserId(userId);
    
    final transactions = allTransactions.where((t) {
      return t.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             t.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categoryTotals = {};
    Map<String, double> dailyTotals = {};
    Map<String, double> vendorTotals = {};
    List<AppTransaction> subscriptions = [];

    // Initialize all 7 days with 0 - always show Mon-Sun
    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var day in allDays) {
      dailyTotals[day] = 0.0;
    }

    for (var t in transactions) {
      if (t.isCredit) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
        vendorTotals[t.merchant] = (vendorTotals[t.merchant] ?? 0) + t.amount;
      }

      final dayName = _getDayName(t.createdAt.weekday);
      dailyTotals[dayName] = (dailyTotals[dayName] ?? 0) + (t.isDebit ? t.amount : 0);

      if (_isSubscription(t)) {
        subscriptions.add(t);
      }
    }

    // Find highest and lowest spending days
    String? highestDay;
    String? lowestDay;
    double highestAmount = 0;
    double lowestAmount = double.infinity;

    dailyTotals.forEach((day, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestDay = day;
      }
      if (amount > 0 && amount < lowestAmount) {
        lowestAmount = amount;
        lowestDay = day;
      }
    });

    // Sort vendors by amount
    var sortedVendors = vendorTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Category percentages
    Map<String, double> categoryPercentages = {};
    categoryTotals.forEach((cat, amount) {
      categoryPercentages[cat] = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0;
    });

    var sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MonthlySummary(
      month: DateFormat('MMMM').format(startDate),
      year: year,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netSavings: totalIncome - totalExpenses,
      transactionCount: transactions.length,
      categoryTotals: categoryTotals,
      categoryPercentages: categoryPercentages,
      sortedCategories: sortedCategories,
      dailyTotals: dailyTotals,
      sortedVendors: sortedVendors,
      highestSpendingDay: highestDay,
      highestSpendingAmount: highestAmount,
      lowestSpendingDay: lowestDay,
      lowestSpendingAmount: lowestAmount == double.infinity ? 0 : lowestAmount,
      subscriptions: subscriptions,
      averageDailySpend: totalExpenses > 0 ? totalExpenses / DateTime(year, month + 1, 0).day : 0,
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ==================== SPENDING TRENDS ====================

  Future<List<MonthlyTrend>> getMonthlyTrends({required int userId, int months = 6}) async {
    List<MonthlyTrend> trends = [];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final summary = await getMonthlySummary(userId: userId, month: adjustedMonth, year: year);
      trends.add(MonthlyTrend(
        month: DateFormat('MMM').format(DateTime(year, adjustedMonth)),
        totalExpenses: summary.totalExpenses,
        totalIncome: summary.totalIncome,
      ));
    }

    return trends;
  }

  // ==================== SUBSCRIPTIONS ====================

  bool _isSubscription(AppTransaction transaction) {
    final merchant = transaction.merchant.toLowerCase();
    final keywords = [
      'netflix', 'spotify', 'amazon prime', 'youtube premium',
      'apple music', 'apple tv', 'google one', 'google drive',
      'dialog postpaid', 'dialog tv', 'mobitel postpaid',
      'slt fibre', 'peo tv', 'zoom pro', 'canva pro',
      'dropbox', 'microsoft 365', 'adobe creative',
      'audible', 'disney+', 'hbo max', 'expressvpn',
    ];

    if (keywords.any((k) => merchant.contains(k))) return true;
    if (transaction.category == 'Recurring Payments') return true;

    return false;
  }

  // ==================== SPENDING PREDICTIONS ====================

  Future<SpendingPrediction> predictMonthlySpending({required int userId}) async {
    final trends = await getMonthlyTrends(userId: userId, months: 6);
    
    if (trends.isEmpty) {
      return SpendingPrediction(
        predictedAmount: 0, confidence: 0,
        trend: 'stable', message: 'Not enough data',
        monthlyTrends: [],
      );
    }

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = trends.length;

    for (int i = 0; i < n; i++) {
      sumX += i.toDouble();
      sumY += trends[i].totalExpenses;
      sumXY += i * trends[i].totalExpenses;
      sumX2 += i * i.toDouble();
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;
    double prediction = intercept + slope * n;

    double meanY = sumY / n;
    double ssRes = 0, ssTot = 0;
    for (int i = 0; i < n; i++) {
      double fitted = intercept + slope * i;
      ssRes += (trends[i].totalExpenses - fitted) * (trends[i].totalExpenses - fitted);
      ssTot += (trends[i].totalExpenses - meanY) * (trends[i].totalExpenses - meanY);
    }
    double rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0;

    String message;
    String trend;
    if (slope > 500) {
      message = 'Spending is trending upward';
      trend = 'up';
    } else if (slope < -500) {
      message = 'Spending is decreasing - great job!';
      trend = 'down';
    } else {
      message = 'Spending is stable';
      trend = 'stable';
    }

    return SpendingPrediction(
      predictedAmount: prediction > 0 ? prediction : trends.last.totalExpenses,
      confidence: rSquared.clamp(0.0, 1.0),
      trend: trend,
      message: message,
      monthlyTrends: trends,
    );
  }

  // ==================== SMART INSIGHTS ====================

  Future<List<SmartInsight>> generateInsights({
    required int userId,
    MonthlySummary? precomputedSummary,
    SpendingPrediction? precomputedPrediction,
    int? month,
    int? year,
  }) async {
    List<SmartInsight> insights = [];
    final summary = precomputedSummary ?? await getMonthlySummary(userId: userId);
    final prediction = precomputedPrediction ?? await predictMonthlySpending(userId: userId);

    if (summary.totalIncome > 0) {
      double savingsRate = (summary.netSavings / summary.totalIncome) * 100;
      if (savingsRate >= 20) {
        insights.add(SmartInsight(
          icon: Icons.savings_rounded,
          title: 'Excellent Savings',
          description: 'You saved ${savingsRate.toStringAsFixed(0)}% of your income this month!',
          type: InsightType.positive,
        ));
      } else if (savingsRate < 10 && summary.totalIncome > 0) {
        insights.add(SmartInsight(
          icon: Icons.warning_rounded,
          title: 'Low Savings Rate',
          description: 'Only ${savingsRate.toStringAsFixed(0)}% saved. Try to save at least 20%.',
          type: InsightType.warning,
        ));
      }
    }

    if (summary.sortedCategories.isNotEmpty) {
      var topCat = summary.sortedCategories.first;
      double pct = summary.categoryPercentages[topCat.key] ?? 0;
      if (pct > 40) {
        String displayName = topCat.key == 'Recurring Payments' ? 'Subscriptions' : topCat.key;
        insights.add(SmartInsight(
          icon: Icons.pie_chart_rounded,
          title: 'Top Spending: $displayName',
          description: '${pct.toStringAsFixed(0)}% of your expenses went to $displayName this month.',
          type: InsightType.warning,
        ));
      }
    }

    insights.add(SmartInsight(
      icon: prediction.trend == 'up' ? Icons.trending_up : Icons.trending_down,
      title: 'Monthly Forecast',
      description: prediction.message,
      type: prediction.trend == 'up' ? InsightType.warning : InsightType.positive,
    ));

    // Weekend vs weekday insight — use selected month/year, not always current month
    double weekendSpend = 0;
    double weekdaySpend = 0;
    int weekendDays = 0;
    int weekdayDays = 0;
    final allTxns = await _db.getTransactionsByUserId(userId);
    final selectedMonth = month ?? DateTime.now().month;
    final selectedYear = year ?? DateTime.now().year;
    final monthTxns = allTxns.where((t) =>
      t.createdAt.month == selectedMonth && t.createdAt.year == selectedYear && t.isDebit
    ).toList();

    for (var t in monthTxns) {
      if (t.createdAt.weekday == 6 || t.createdAt.weekday == 7) {
        weekendSpend += t.amount;
        weekendDays++;
      } else {
        weekdaySpend += t.amount;
        weekdayDays++;
      }
    }

    double weekendAvg = weekendDays > 0 ? weekendSpend / weekendDays : 0;
    double weekdayAvg = weekdayDays > 0 ? weekdaySpend / weekdayDays : 0;

    if (weekendAvg > weekdayAvg * 1.3 && weekendDays > 0) {
      insights.add(SmartInsight(
        icon: Icons.weekend_rounded,
        title: 'Weekend Spender',
        description: 'You spend ${((weekendAvg / weekdayAvg - 1) * 100).toStringAsFixed(0)}% more on weekends.',
        type: InsightType.info,
      ));
    }

    // Subscription insight — filter to current month only
    final recurringTxs = monthTxns.where((t) => t.isDebit && _isSubscription(t)).toList();
    if (recurringTxs.isNotEmpty) {
      final uniqueSubs = <String, double>{};
      for (var t in recurringTxs) {
        uniqueSubs[t.merchant] = (uniqueSubs[t.merchant] ?? 0) + t.amount;
      }
      double monthlySubs = uniqueSubs.values.fold(0.0, (sum, v) => sum + v);
      insights.add(SmartInsight(
        icon: Icons.subscriptions_rounded,
        title: 'Active Subscriptions',
        description: '${uniqueSubs.length} subscriptions totaling LKR ${NumberFormat('#,##0').format(monthlySubs)}/mo',
        type: InsightType.info,
      ));
    }

    return insights;
  }

  /// Get transactions for a specific category in a given month
Future<List<AppTransaction>> getTransactionsByCategory({
  required int userId,
  required String category,
  int? month,
  int? year,
}) async {
  month ??= DateTime.now().month;
  year ??= DateTime.now().year;

  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

  final allTransactions = await _db.getTransactionsByUserId(userId);
  
  return allTransactions.where((t) {
    return t.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
           t.createdAt.isBefore(endDate.add(const Duration(seconds: 1))) &&
           t.category == category;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

}

// ==================== DATA MODELS ====================

class MonthlySummary {
  final String month;
  final int year;
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final int transactionCount;
  final Map<String, double> categoryTotals;
  final Map<String, double> categoryPercentages;
  final List<MapEntry<String, double>> sortedCategories;
  final Map<String, double> dailyTotals;
  final List<MapEntry<String, double>> sortedVendors;
  final String? highestSpendingDay;
  final double highestSpendingAmount;
  final String? lowestSpendingDay;
  final double lowestSpendingAmount;
  final List<AppTransaction> subscriptions;
  final double averageDailySpend;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.transactionCount,
    required this.categoryTotals,
    required this.categoryPercentages,
    required this.sortedCategories,
    required this.dailyTotals,
    required this.sortedVendors,
    this.highestSpendingDay,
    required this.highestSpendingAmount,
    this.lowestSpendingDay,
    required this.lowestSpendingAmount,
    required this.subscriptions,
    required this.averageDailySpend,
  });
}

class MonthlyTrend {
  final String month;
  final double totalExpenses;
  final double totalIncome;
  MonthlyTrend({required this.month, required this.totalExpenses, required this.totalIncome});
}

class SpendingPrediction {
  final double predictedAmount;
  final double confidence;
  final String trend;
  final String message;
  final List<MonthlyTrend> monthlyTrends;
  SpendingPrediction({required this.predictedAmount, required this.confidence, required this.trend, required this.message, required this.monthlyTrends});
}

class SmartInsight {
  final IconData icon;
  final String title;
  final String description;
  final InsightType type;
  SmartInsight({required this.icon, required this.title, required this.description, required this.type});
}

enum InsightType { positive, warning, info }