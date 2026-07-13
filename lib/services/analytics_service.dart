// File: lib/services/analytics_service.dart
import 'package:flutter/material.dart';  // ← ADD THIS
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'database_service.dart';

class AnalyticsService {
  final DatabaseService _db = DatabaseService();

  // ==================== MONTHLY SUMMARIES ====================

  Future<MonthlySummary> getMonthlySummary({int? month, int? year}) async {
    month ??= DateTime.now().month;
    year ??= DateTime.now().year;

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // FIXED: Use correct Isar query syntax
    final allTransactions = await _db.getAllTransactions();
    
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

    for (var t in transactions) {
      if (t.isCredit) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
        vendorTotals[t.merchant] = (vendorTotals[t.merchant] ?? 0) + t.amount;
      }

      final day = DateFormat('EEE').format(t.createdAt);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + (t.isDebit ? t.amount : 0);

      if (_isSubscription(t)) {
        subscriptions.add(t);
      }
    }

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

    String? topVendor;
    double topVendorAmount = 0;
    vendorTotals.forEach((vendor, amount) {
      if (amount > topVendorAmount) {
        topVendorAmount = amount;
        topVendor = vendor;
      }
    });

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
      vendorTotals: vendorTotals,
      topVendor: topVendor,
      topVendorAmount: topVendorAmount,
      highestSpendingDay: highestDay,
      highestSpendingAmount: highestAmount,
      lowestSpendingDay: lowestDay,
      lowestSpendingAmount: lowestAmount == double.infinity ? 0 : lowestAmount,
      subscriptions: subscriptions,
      averageDailySpend: totalExpenses > 0 ? totalExpenses / DateTime(year, month + 1, 0).day : 0,
    );
  }

  // ==================== SPENDING TRENDS ====================

  Future<List<MonthlyTrend>> getMonthlyTrends({int months = 6}) async {
    List<MonthlyTrend> trends = [];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final summary = await getMonthlySummary(month: adjustedMonth, year: year);
      trends.add(MonthlyTrend(
        month: DateFormat('MMM').format(DateTime(year, adjustedMonth)),
        totalExpenses: summary.totalExpenses,
        totalIncome: summary.totalIncome,
      ));
    }

    return trends;
  }

  // ==================== RECURRING PAYMENTS ====================

  bool _isSubscription(AppTransaction transaction) {
    final merchant = transaction.merchant.toLowerCase();
    final keywords = [
      'netflix', 'spotify', 'amazon prime', 'youtube', 'apple',
      'google', 'dialog', 'mobitel', 'slt', 'peo tv',
      'zoom', 'canva', 'dropbox', 'microsoft', 'adobe',
      'audible', 'disney', 'hbo', 'expressvpn',
    ];

    if (keywords.any((k) => merchant.contains(k))) return true;
    if (transaction.category == 'Recurring Payments') return true;

    return false;
  }

  // ==================== SPENDING PREDICTIONS ====================

  Future<SpendingPrediction> predictMonthlySpending() async {
    final trends = await getMonthlyTrends(months: 6);
    
    if (trends.isEmpty) {
      // FIXED: Provide all required parameters
      return SpendingPrediction(
        predictedAmount: 0, 
        confidence: 0,
        trend: 'stable',
        message: 'Not enough data for predictions',
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
      message = 'Your spending is trending upward';
      trend = 'up';
    } else if (slope < -500) {
      message = 'Great job! Your spending is decreasing';
      trend = 'down';
    } else {
      message = 'Your spending is stable';
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

  Future<List<SmartInsight>> generateInsights() async {
    List<SmartInsight> insights = [];
    final summary = await getMonthlySummary();
    final prediction = await predictMonthlySpending();
    final now = DateTime.now();

    // Insight 1: Savings rate
    if (summary.totalIncome > 0) {
      double savingsRate = (summary.netSavings / summary.totalIncome) * 100;
      if (savingsRate >= 20) {
        insights.add(SmartInsight(
          icon: Icons.savings_rounded,
          title: 'Excellent Savings Rate',
          description: 'You saved ${savingsRate.toStringAsFixed(1)}% of your income this month!',
          type: InsightType.positive,
        ));
      } else if (savingsRate < 10) {
        insights.add(SmartInsight(
          icon: Icons.warning_rounded,
          title: 'Low Savings Alert',
          description: 'Only ${savingsRate.toStringAsFixed(1)}% saved. Aim for at least 20%.',
          type: InsightType.warning,
        ));
      }
    }

    // Insight 2: Top spending category
    if (summary.sortedCategories.isNotEmpty) {
      var topCat = summary.sortedCategories.first;
      double pct = summary.categoryPercentages[topCat.key] ?? 0;
      if (pct > 40) {
        insights.add(SmartInsight(
          icon: Icons.pie_chart_rounded,
          title: 'High ${topCat.key} Spending',
          description: '${pct.toStringAsFixed(0)}% of expenses went to ${topCat.key}.',
          type: InsightType.warning,
        ));
      }
    }

    // Insight 3: Spending trend
    insights.add(SmartInsight(
      icon: prediction.trend == 'up' ? Icons.trending_up : Icons.trending_down,
      title: 'Spending Forecast',
      description: '${prediction.message}. Predicted next month: LKR ${prediction.predictedAmount.toStringAsFixed(0)}',
      type: prediction.trend == 'up' ? InsightType.warning : InsightType.positive,
    ));

    // Insight 4: Subscriptions
    final allTxns = await _db.getAllTransactions();
    final recurringTxs = allTxns.where((t) => t.isDebit && _isSubscription(t)).toList();
    if (recurringTxs.isNotEmpty) {
      double monthlySubs = recurringTxs.fold(0.0, (sum, t) => sum + t.amount);
      insights.add(SmartInsight(
        icon: Icons.repeat_rounded,
        title: 'Recurring Payments',
        description: 'You have ${recurringTxs.length} recurring payments (LKR ${monthlySubs.toStringAsFixed(0)}/mo)',
        type: InsightType.info,
      ));
    }

    return insights;
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
  final Map<String, double> vendorTotals;
  final String? topVendor;
  final double topVendorAmount;
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
    required this.vendorTotals,
    this.topVendor,
    required this.topVendorAmount,
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

  MonthlyTrend({
    required this.month,
    required this.totalExpenses,
    required this.totalIncome,
  });
}

class SpendingPrediction {
  final double predictedAmount;
  final double confidence;
  final String trend;
  final String message;
  final List<MonthlyTrend> monthlyTrends;

  SpendingPrediction({
    required this.predictedAmount,
    required this.confidence,
    required this.trend,
    required this.message,
    required this.monthlyTrends,
  });
}

class SmartInsight {
  final IconData icon;
  final String title;
  final String description;
  final InsightType type;

  SmartInsight({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
  });
}

enum InsightType { positive, warning, info }