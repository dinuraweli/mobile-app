// File: lib/services/tax_calculator_service.dart

class TaxCalculatorService {
  // ==================== SRI LANKA TAX RATES (Effective April 2025) ====================
  // Source: Inland Revenue Department PN/IT/2025-01 dated 26.03.2025
  
  static const List<TaxBracket> taxBrackets = [
    TaxBracket(0, 1000000, 0.06, 'First Rs. 1,000,000'),
    TaxBracket(1000000, 1500000, 0.18, 'Next Rs. 500,000'),
    TaxBracket(1500000, 2000000, 0.24, 'Next Rs. 500,000'),
    TaxBracket(2000000, 2500000, 0.30, 'Next Rs. 500,000'),
    TaxBracket(2500000, double.infinity, 0.36, 'Balance above Rs. 2,500,000'),
  ];

  static const double annualTaxFreeAllowance = 1800000;
  static const double monthlyTaxFreeAllowance = 150000;

  static const double epfEmployeeRate = 0.08;
  static const double epfEmployerRate = 0.12;
  static const double etfEmployerRate = 0.03;

  // ==================== CALCULATION ENGINE ====================

  static TaxCalculationResult calculate({
    required double monthlyBasicSalary,
    double monthlyBonus = 0,
    double monthlyCommission = 0,
    double monthlyAllowances = 0,
  }) {
    double totalMonthlyEarnings = monthlyBasicSalary + monthlyBonus + monthlyCommission + monthlyAllowances;
    
    double monthlyEpfEmployee = totalMonthlyEarnings * epfEmployeeRate;
    double monthlyEpfEmployer = totalMonthlyEarnings * epfEmployerRate;
    double monthlyEtfEmployer = totalMonthlyEarnings * etfEmployerRate;
    double totalEmployerContribution = monthlyEpfEmployer + monthlyEtfEmployer;
    
    double annualGrossSalary = totalMonthlyEarnings * 12;
    double annualEpfEmployee = monthlyEpfEmployee * 12;
    double annualEpfEmployer = monthlyEpfEmployer * 12;
    double annualEtfEmployer = monthlyEtfEmployer * 12;
    
    // Tax on GROSS salary (before EPF per IRD rules)
    double annualTaxableIncome = (annualGrossSalary - annualTaxFreeAllowance).clamp(0, double.infinity);
    
    double annualTax = 0;
    List<TaxBracketBreakdown> bracketBreakdowns = [];
    double remaining = annualTaxableIncome;
    
    for (var bracket in taxBrackets) {
      if (remaining <= 0) break;
      double bracketRange = bracket.maxAmount - bracket.minAmount;
      double taxableInBracket = remaining > bracketRange ? bracketRange : remaining;
      double taxInBracket = taxableInBracket * bracket.rate;
      if (taxableInBracket > 0) {
        bracketBreakdowns.add(TaxBracketBreakdown(
          label: bracket.label,
          rate: bracket.rate,
          taxableAmount: taxableInBracket,
          taxAmount: taxInBracket,
        ));
      }
      annualTax += taxInBracket;
      remaining -= taxableInBracket;
    }
    
    double monthlyTax = annualTax / 12;
    double monthlyNetSalary = totalMonthlyEarnings - monthlyEpfEmployee - monthlyTax;
    double annualNetSalary = monthlyNetSalary * 12;
    double effectiveTaxRate = annualGrossSalary > 0 ? (annualTax / annualGrossSalary) * 100 : 0;

    return TaxCalculationResult(
      monthlyBasicSalary: monthlyBasicSalary,
      monthlyBonus: monthlyBonus,
      monthlyCommission: monthlyCommission,
      monthlyAllowances: monthlyAllowances,
      totalMonthlyEarnings: totalMonthlyEarnings,
      monthlyEpfEmployee: monthlyEpfEmployee,
      monthlyTax: monthlyTax,
      monthlyTakeHome: monthlyNetSalary,
      monthlyEpfEmployer: monthlyEpfEmployer,
      monthlyEtfEmployer: monthlyEtfEmployer,
      totalMonthlyEmployerContribution: totalEmployerContribution,
      annualGrossSalary: annualGrossSalary,
      annualTaxableIncome: annualTaxableIncome,
      annualTax: annualTax,
      annualNetSalary: annualNetSalary,
      annualEpfEmployee: annualEpfEmployee,
      annualEpfEmployer: annualEpfEmployer,
      annualEtfEmployer: annualEtfEmployer,
      effectiveTaxRate: effectiveTaxRate,
      bracketBreakdowns: bracketBreakdowns,
    );
  }
}

// ==================== DATA MODELS ====================

class TaxBracket {
  final double minAmount;
  final double maxAmount;
  final double rate;
  final String label;

  const TaxBracket(this.minAmount, this.maxAmount, this.rate, this.label);
}

class TaxBracketBreakdown {
  final String label;
  final double rate;
  final double taxableAmount;
  final double taxAmount;

  TaxBracketBreakdown({
    required this.label,
    required this.rate,
    required this.taxableAmount,
    required this.taxAmount,
  });
}

class TaxCalculationResult {
  final double monthlyBasicSalary;
  final double monthlyBonus;
  final double monthlyCommission;
  final double monthlyAllowances;
  final double totalMonthlyEarnings;
  final double monthlyEpfEmployee;
  final double monthlyTax;
  final double monthlyTakeHome;
  final double monthlyEpfEmployer;
  final double monthlyEtfEmployer;
  final double totalMonthlyEmployerContribution;
  final double annualGrossSalary;
  final double annualTaxableIncome;
  final double annualTax;
  final double annualNetSalary;
  final double annualEpfEmployee;
  final double annualEpfEmployer;
  final double annualEtfEmployer;
  final double effectiveTaxRate;
  final List<TaxBracketBreakdown> bracketBreakdowns;

  TaxCalculationResult({
    required this.monthlyBasicSalary,
    required this.monthlyBonus,
    required this.monthlyCommission,
    required this.monthlyAllowances,
    required this.totalMonthlyEarnings,
    required this.monthlyEpfEmployee,
    required this.monthlyTax,
    required this.monthlyTakeHome,
    required this.monthlyEpfEmployer,
    required this.monthlyEtfEmployer,
    required this.totalMonthlyEmployerContribution,
    required this.annualGrossSalary,
    required this.annualTaxableIncome,
    required this.annualTax,
    required this.annualNetSalary,
    required this.annualEpfEmployee,
    required this.annualEpfEmployer,
    required this.annualEtfEmployer,
    required this.effectiveTaxRate,
    required this.bracketBreakdowns,
  });

  double get taxPercentage => totalMonthlyEarnings > 0 ? (monthlyTax / totalMonthlyEarnings) * 100 : 0;
  double get epfPercentage => totalMonthlyEarnings > 0 ? (monthlyEpfEmployee / totalMonthlyEarnings) * 100 : 0;
  double get takeHomePercentage => totalMonthlyEarnings > 0 ? (monthlyTakeHome / totalMonthlyEarnings) * 100 : 0;
}