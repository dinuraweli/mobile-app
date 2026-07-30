// File: lib/services/sl_financial_data.dart

class SLFinancialData {
  // ==================== CONSTANTS ====================
  
  static const double epfEmployeeRate = 0.08;
  static const double epfEmployerRate = 0.12;
  static const double etfEmployerRate = 0.03;
  static const double epfInterestRate = 0.09;

  // ==================== FD RATES ====================

  static const Map<String, Map<String, double>> fdRates = {
    'Commercial Bank': {'3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.105, '2 Years': 0.11, '3 Years': 0.115, '5 Years': 0.12},
    'HNB': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
    'Sampath Bank': {'3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.1025, '2 Years': 0.1075, '3 Years': 0.1125, '5 Years': 0.1175},
    'BOC': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
    'NDB': {'3 Months': 0.09, '6 Months': 0.095, '1 Year': 0.1075, '2 Years': 0.1125, '3 Years': 0.1175, '5 Years': 0.1225},
    'Peoples Bank': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
  };

  // ==================== LTV RATIOS ====================

  static const Map<String, VehicleLTV> ltvRatios = {
    'Car (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered cars over 1 year old'),
    'Car (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'SUV (Registered)': VehicleLTV(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered SUVs over 1 year old'),
    'SUV (Unregistered)': VehicleLTV(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
    'Electric Car': VehicleLTV(category: 'Electric Vehicle', ltv: 0.60, description: 'Electric vehicles - special rate'),
    'Commercial Vehicle': VehicleLTV(category: 'Commercial Vehicle', ltv: 0.60, description: 'Commercial vehicles'),
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
    'Car (Registered)', 'Car (Unregistered)', 'SUV (Registered)', 'SUV (Unregistered)',
    'Electric Car', 'Commercial Vehicle',
  ];

  static const List<String> leasingBanks = [
    'Commercial Bank', 'HNB', 'Sampath Bank', 'BOC', 'NDB', 'Peoples Bank', 'Seylan Bank',
  ];

  static const List<int> tenureOptions = [12, 24, 36, 48, 60];

  // ==================== LOAN TYPES ====================

  static const List<LoanType> loanTypes = [
    LoanType(name: 'Personal Loan', minRate: 0.12, maxRate: 0.18, maxTenure: 60, maxAmount: 5000000, description: 'Unsecured loans for personal needs', typicalRates: {
      'Commercial Bank': 0.12, 'HNB': 0.13, 'Sampath Bank': 0.125, 'BOC': 0.13, 'NDB': 0.14, 'Peoples Bank': 0.135, 'Seylan Bank': 0.14,
    }),
    LoanType(name: 'Housing Loan', minRate: 0.08, maxRate: 0.12, maxTenure: 300, maxAmount: 50000000, description: 'Home construction, purchase, or renovation', typicalRates: {
      'Commercial Bank': 0.09, 'HNB': 0.095, 'Sampath Bank': 0.09, 'BOC': 0.085, 'NDB': 0.10, 'Peoples Bank': 0.09, 'Seylan Bank': 0.10,
    }),
    LoanType(name: 'Vehicle Loan', minRate: 0.12, maxRate: 0.16, maxTenure: 60, maxAmount: 20000000, description: 'New or used vehicle purchase', typicalRates: {
      'Commercial Bank': 0.12, 'HNB': 0.13, 'Sampath Bank': 0.125, 'BOC': 0.13, 'NDB': 0.115, 'Peoples Bank': 0.125, 'Seylan Bank': 0.13,
    }),
    LoanType(name: 'Education Loan', minRate: 0.06, maxRate: 0.10, maxTenure: 120, maxAmount: 10000000, description: 'Local or foreign education expenses', typicalRates: {
      'Commercial Bank': 0.08, 'HNB': 0.085, 'Sampath Bank': 0.08, 'BOC': 0.075, 'NDB': 0.09, 'Peoples Bank': 0.08, 'Seylan Bank': 0.09,
    }),
    LoanType(name: 'Solar Loan', minRate: 0.06, maxRate: 0.09, maxTenure: 84, maxAmount: 3000000, description: 'Solar panel installation financing', typicalRates: {
      'Commercial Bank': 0.07, 'HNB': 0.075, 'Sampath Bank': 0.07, 'BOC': 0.065, 'NDB': 0.08, 'Peoples Bank': 0.07, 'Seylan Bank': 0.08,
    }),
    LoanType(name: 'Business Loan', minRate: 0.10, maxRate: 0.16, maxTenure: 120, maxAmount: 25000000, description: 'SME and business expansion funding', typicalRates: {
      'Commercial Bank': 0.11, 'HNB': 0.12, 'Sampath Bank': 0.115, 'BOC': 0.11, 'NDB': 0.125, 'Peoples Bank': 0.12, 'Seylan Bank': 0.13,
    }),
  ];

  static const List<String> loanBanks = [
    'Commercial Bank', 'HNB', 'Sampath Bank', 'BOC', 'NDB', 'Peoples Bank', 'Seylan Bank',
  ];

  static const List<int> loanTenureOptions = [12, 24, 36, 48, 60, 84, 120, 180, 240, 300];
}

// ==================== HELPER CLASSES ====================

class VehicleLTV {
  final String category, description;
  final double ltv;
  const VehicleLTV({required this.category, required this.ltv, required this.description});
}

class LoanType {
  final String name, description;
  final double minRate, maxRate, maxAmount;
  final int maxTenure;
  final Map<String, double> typicalRates;
  const LoanType({required this.name, required this.minRate, required this.maxRate, required this.maxTenure, required this.maxAmount, required this.description, required this.typicalRates});
}

class AmortizationEntry {
  final int month;
  final double emi, principal, interest, balance;
  AmortizationEntry({required this.month, required this.emi, required this.principal, required this.interest, required this.balance});
}