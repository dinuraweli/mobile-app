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

  // ==================== FD RATES ====================

  static const Map<String, Map<String, double>> fdRates = {
    'Commercial Bank': {
      '3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.105, '2 Years': 0.11, '3 Years': 0.115, '5 Years': 0.12,
    },
    'HNB': {
      '3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115,
    },
    'Sampath Bank': {
      '3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.1025, '2 Years': 0.1075, '3 Years': 0.1125, '5 Years': 0.1175,
    },
    'BOC': {
      '3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115,
    },
    'NDB': {
      '3 Months': 0.09, '6 Months': 0.095, '1 Year': 0.1075, '2 Years': 0.1125, '3 Years': 0.1175, '5 Years': 0.1225,
    },
    'Peoples Bank': {
      '3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115,
    },
  };

  // ==================== VEHICLE LEASING - CBSL 2026 LTV RATIOS ====================
  
  static const Map<String, VehicleLTV> ltvRatios = {
    'Car (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered cars over 1 year old'),
    'Car (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'SUV (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered SUVs over 1 year old'),
    'SUV (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'Van (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered vans over 1 year old'),
    'Van (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'Three Wheeler (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered three-wheelers over 1 year old'),
    'Three Wheeler (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'Electric Car': VehicleLTV(category: 'Electric Vehicle', ltv: 0.60, description: 'Electric vehicles - special rate'),
    'Commercial Vehicle': VehicleLTV(category: 'Commercial Vehicle', ltv: 0.60, description: 'Commercial vehicles'),
    'Motorcycle (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered motorcycles over 1 year old'),
    'Motorcycle (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
  };

  static const Map<String, Map<int, double>> bankLeasingRates = {
    'Commercial Bank': {12: 0.12, 24: 0.125, 36: 0.13, 48: 0.135, 60: 0.14},
    'HNB': {12: 0.125, 24: 0.13, 36: 0.135, 48: 0.14, 60: 0.145},
    'Sampath Bank': {12: 0.12, 24: 0.125, 36: 0.13, 48: 0.135, 60: 0.14},
    'BOC': {12: 0.13, 24: 0.135, 36: 0.14, 48: 0.145, 60: 0.15},
    'NDB': {12: 0.115, 24: 0.12, 36: 0.125, 48: 0.13, 60: 0.135},
    'Peoples Bank': {12: 0.125, 24: 0.13, 36: 0.135, 48: 0.14, 60: 0.145},
    'Seylan Bank': {12: 0.13, 24: 0.135, 36: 0.14, 48: 0.145, 60: 0.15},
  };

  static const List<String> vehicleCategories = [
    'Car (Registered)', 'Car (Unregistered)',
    'SUV (Registered)', 'SUV (Unregistered)',
    'Van (Registered)', 'Van (Unregistered)',
    'Three Wheeler (Registered)', 'Three Wheeler (Unregistered)',
    'Electric Car', 'Commercial Vehicle',
    'Motorcycle (Registered)', 'Motorcycle (Unregistered)',
  ];

  static const List<String> leasingBanks = [
    'Commercial Bank', 'HNB', 'Sampath Bank', 'BOC', 'NDB', 'Peoples Bank', 'Seylan Bank',
  ];

  static const List<int> tenureOptions = [12, 24, 36, 48, 60];

  // ==================== PERSONAL LOAN RATES ====================

  static const Map<String, double> personalLoanRates = {
    'Commercial Bank': 0.12, 'HNB': 0.13, 'Sampath Bank': 0.125,
    'BOC': 0.13, 'NDB': 0.14, 'Peoples Bank': 0.135,
  };

  // ==================== CALCULATORS ====================

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

class VehicleLTV {
  final String category;
  final double ltv;
  final String description;
  const VehicleLTV({required this.category, required this.ltv, required this.description});
}