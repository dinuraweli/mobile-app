// File: lib/services/sl_financial_data.dart
import 'dart:math' as math;

class SLFinancialData {
  // ==================== TAX RATES (2025/2026) ====================
  
  static const List<TaxBracket> apitBrackets = [
    TaxBracket(0, 500000, 0.06),
    TaxBracket(500000, 1000000, 0.12),
    TaxBracket(1000000, 1500000, 0.18),
    TaxBracket(1500000, 2000000, 0.24),
    TaxBracket(2000000, double.infinity, 0.30),
  ];

  static const List<TaxBracket> payeBrackets = apitBrackets;
  static const double taxFreeAllowance = 1200000;
  static const double epfEmployeeRate = 0.08;
  static const double epfEmployerRate = 0.12;
  static const double etfEmployerRate = 0.03;
  static const double epfInterestRate = 0.09;

  static const Map<String, Map<String, double>> fdRates = {
    'Commercial Bank': {
      '3 Months': 0.085,
      '6 Months': 0.09,
      '1 Year': 0.105,
      '2 Years': 0.11,
      '3 Years': 0.115,
      '5 Years': 0.12,
    },
    'HNB': {
      '3 Months': 0.08,
      '6 Months': 0.085,
      '1 Year': 0.10,
      '2 Years': 0.105,
      '3 Years': 0.11,
      '5 Years': 0.115,
    },
    'Sampath Bank': {
      '3 Months': 0.085,
      '6 Months': 0.09,
      '1 Year': 0.1025,
      '2 Years': 0.1075,
      '3 Years': 0.1125,
      '5 Years': 0.1175,
    },
    'BOC': {
      '3 Months': 0.08,
      '6 Months': 0.085,
      '1 Year': 0.10,
      '2 Years': 0.105,
      '3 Years': 0.11,
      '5 Years': 0.115,
    },
    'NDB': {
      '3 Months': 0.09,
      '6 Months': 0.095,
      '1 Year': 0.1075,
      '2 Years': 0.1125,
      '3 Years': 0.1175,
      '5 Years': 0.1225,
    },
    'Peoples Bank': {
      '3 Months': 0.08,
      '6 Months': 0.085,
      '1 Year': 0.10,
      '2 Years': 0.105,
      '3 Years': 0.11,
      '5 Years': 0.115,
    },
  };

  static const Map<String, LeasingRate> leasingRates = {
    'Brand New Car': LeasingRate(minRate: 0.12, maxRate: 0.16, maxTenure: 60, maxLoanToValue: 0.80),
    'Reconditioned Car': LeasingRate(minRate: 0.14, maxRate: 0.18, maxTenure: 60, maxLoanToValue: 0.75),
    'Brand New SUV': LeasingRate(minRate: 0.13, maxRate: 0.17, maxTenure: 60, maxLoanToValue: 0.75),
    'Three Wheeler': LeasingRate(minRate: 0.15, maxRate: 0.20, maxTenure: 48, maxLoanToValue: 0.70),
    'Motorcycle': LeasingRate(minRate: 0.16, maxRate: 0.22, maxTenure: 36, maxLoanToValue: 0.65),
  };

  static const Map<String, double> personalLoanRates = {
    'Commercial Bank': 0.12,
    'HNB': 0.13,
    'Sampath Bank': 0.125,
    'BOC': 0.13,
    'NDB': 0.14,
    'Peoples Bank': 0.135,
  };

  static double calculateMonthlyTax(double monthlySalary) {
    double annualSalary = monthlySalary * 12;
    double taxableIncome = (annualSalary - taxFreeAllowance).clamp(0, double.infinity);
    
    double annualTax = 0;
    double remaining = taxableIncome;
    
    for (var bracket in apitBrackets) {
      if (remaining <= 0) break;
      double bracketRange = bracket.maxAmount - bracket.minAmount;
      double taxableInBracket = remaining > bracketRange ? bracketRange : remaining;
      annualTax += taxableInBracket * bracket.rate;
      remaining -= taxableInBracket;
    }
    
    return annualTax / 12;
  }

  static Map<String, double> calculateEPF(double monthlySalary) {
    double employeeContribution = monthlySalary * epfEmployeeRate;
    double employerContribution = monthlySalary * epfEmployerRate;
    double totalMonthly = employeeContribution + employerContribution;
    
    return {
      'employee': employeeContribution,
      'employer': employerContribution,
      'totalMonthly': totalMonthly,
      'totalYearly': totalMonthly * 12,
    };
  }

  static double calculateETF(double monthlySalary) {
    return monthlySalary * etfEmployerRate;
  }

  static double projectEPFBalance(double monthlySalary, int years) {
    double monthlyContribution = monthlySalary * (epfEmployeeRate + epfEmployerRate);
    double monthlyRate = epfInterestRate / 12;
    int months = years * 12;
    
    double futureValue = monthlyContribution * 
        ((math.pow(1 + monthlyRate, months) - 1) / monthlyRate) * 
        (1 + monthlyRate);
    
    return futureValue;
  }
}

// ==================== HELPER CLASSES ====================

class TaxBracket {
  final double minAmount;
  final double maxAmount;
  final double rate;

  const TaxBracket(this.minAmount, this.maxAmount, this.rate);
}

class LeasingRate {
  final double minRate;
  final double maxRate;
  final int maxTenure;
  final double maxLoanToValue;

  const LeasingRate({
    required this.minRate,
    required this.maxRate,
    required this.maxTenure,
    required this.maxLoanToValue,
  });
}