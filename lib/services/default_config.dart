// File: lib/services/default_config.dart
import '../models/financial_config.dart';

class DefaultConfig {
  /// These are the BUILT-IN defaults. Used when:
  /// - First launch with no internet
  /// - Cache expired and fetch fails
  /// - Remote config is broken
  static FinancialConfig get defaultConfig {
    return FinancialConfig(
      version: '2026.07-builtin',
      source: 'default',
      fetchedAt: DateTime(2026, 7, 15),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      
      // Tax - Based on IRD 2025/2026
      taxFreeAllowance: 1800000,
      taxBrackets: [
        TaxBracketConfig(minAmount: 0, maxAmount: 1000000, rate: 0.06, label: 'First Rs. 1,000,000'),
        TaxBracketConfig(minAmount: 1000000, maxAmount: 1500000, rate: 0.18, label: 'Next Rs. 500,000'),
        TaxBracketConfig(minAmount: 1500000, maxAmount: 2000000, rate: 0.24, label: 'Next Rs. 500,000'),
        TaxBracketConfig(minAmount: 2000000, maxAmount: 2500000, rate: 0.30, label: 'Next Rs. 500,000'),
        TaxBracketConfig(minAmount: 2500000, maxAmount: double.infinity, rate: 0.36, label: 'Balance above Rs. 2,500,000'),
      ],
      
      // EPF/ETF
      epfEmployeeRate: 0.08,
      epfEmployerRate: 0.12,
      etfEmployerRate: 0.03,
      epfInterestRate: 0.09,
      
      // LTV Ratios - CBSL May 2026
      ltvRatios: {
        'Car (Registered)': LTVConfig(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered cars over 1 year old'),
        'Car (Unregistered)': LTVConfig(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
        'SUV (Registered)': LTVConfig(category: 'Registered Vehicle', ltv: 0.70, description: 'Registered SUVs over 1 year old'),
        'SUV (Unregistered)': LTVConfig(category: 'Unregistered Vehicle', ltv: 0.40, description: 'Brand new / less than 1 year old'),
        'Electric Car': LTVConfig(category: 'Electric Vehicle', ltv: 0.60, description: 'Electric vehicles - special rate'),
        'Commercial Vehicle': LTVConfig(category: 'Commercial Vehicle', ltv: 0.60, description: 'Commercial vehicles'),
      },
      
      // Bank leasing rates
      bankLeasingRates: {
        'Commercial Bank': {12: 0.12, 24: 0.125, 36: 0.13, 48: 0.135, 60: 0.14},
        'HNB': {12: 0.125, 24: 0.13, 36: 0.135, 48: 0.14, 60: 0.145},
        'Sampath Bank': {12: 0.12, 24: 0.125, 36: 0.13, 48: 0.135, 60: 0.14},
        'BOC': {12: 0.13, 24: 0.135, 36: 0.14, 48: 0.145, 60: 0.15},
        'NDB': {12: 0.115, 24: 0.12, 36: 0.125, 48: 0.13, 60: 0.135},
        'Peoples Bank': {12: 0.125, 24: 0.13, 36: 0.135, 48: 0.14, 60: 0.145},
        'Seylan Bank': {12: 0.13, 24: 0.135, 36: 0.14, 48: 0.145, 60: 0.15},
      },
      
      // FD rates
      fdRates: {
        'Commercial Bank': {'3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.105, '2 Years': 0.11, '3 Years': 0.115, '5 Years': 0.12},
        'HNB': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
        'Sampath Bank': {'3 Months': 0.085, '6 Months': 0.09, '1 Year': 0.1025, '2 Years': 0.1075, '3 Years': 0.1125, '5 Years': 0.1175},
        'BOC': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
        'NDB': {'3 Months': 0.09, '6 Months': 0.095, '1 Year': 0.1075, '2 Years': 0.1125, '3 Years': 0.1175, '5 Years': 0.1225},
        'Peoples Bank': {'3 Months': 0.08, '6 Months': 0.085, '1 Year': 0.10, '2 Years': 0.105, '3 Years': 0.11, '5 Years': 0.115},
      },
      
      // Personal loan rates
      personalLoanRates: {
        'Commercial Bank': 0.12, 'HNB': 0.13, 'Sampath Bank': 0.125,
        'BOC': 0.13, 'NDB': 0.14, 'Peoples Bank': 0.135,
      },
    );
  }
}