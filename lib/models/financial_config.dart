// File: lib/models/financial_config.dart

class FinancialConfig {
  final String version;
  final String source; // 'remote', 'cache', 'default'
  final DateTime fetchedAt;
  final DateTime expiresAt;
  
  // Tax data
  final double taxFreeAllowance;
  final List<TaxBracketConfig> taxBrackets;
  
  // EPF/ETF
  final double epfEmployeeRate;
  final double epfEmployerRate;
  final double etfEmployerRate;
  final double epfInterestRate;
  
  // LTV ratios
  final Map<String, LTVConfig> ltvRatios;
  
  // Bank leasing rates
  final Map<String, Map<int, double>> bankLeasingRates;
  
  // Bank FD rates
  final Map<String, Map<String, double>> fdRates;
  
  // Personal loan rates
  final Map<String, double> personalLoanRates;

  FinancialConfig({
    required this.version,
    required this.source,
    required this.fetchedAt,
    required this.expiresAt,
    required this.taxFreeAllowance,
    required this.taxBrackets,
    required this.epfEmployeeRate,
    required this.epfEmployerRate,
    required this.etfEmployerRate,
    required this.epfInterestRate,
    required this.ltvRatios,
    required this.bankLeasingRates,
    required this.fdRates,
    required this.personalLoanRates,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isRemote => source == 'remote';
  bool get isDefault => source == 'default';
  
  String get sourceLabel {
    switch (source) {
      case 'remote': return 'Latest from IRD/CBSL';
      case 'cache': return 'Cached (${_timeAgo(fetchedAt)})';
      case 'default': return 'Built-in defaults';
      default: return source;
    }
  }
  
  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'fetched_at': fetchedAt.toIso8601String(),
    'tax_free_allowance': taxFreeAllowance,
    'tax_brackets': taxBrackets.map((b) => b.toJson()).toList(),
    'epf_employee_rate': epfEmployeeRate,
    'epf_employer_rate': epfEmployerRate,
    'etf_employer_rate': etfEmployerRate,
    'epf_interest_rate': epfInterestRate,
    'ltv_ratios': ltvRatios.map((k, v) => MapEntry(k, v.toJson())),
    'bank_leasing_rates': bankLeasingRates.map((k, v) => MapEntry(k, v.map((tk, tv) => MapEntry(tk.toString(), tv)))),
    'fd_rates': fdRates,
    'personal_loan_rates': personalLoanRates,
  };

  factory FinancialConfig.fromJson(Map<String, dynamic> json, {String source = 'cache'}) {
    return FinancialConfig(
      version: json['version'] ?? 'unknown',
      source: source,
      fetchedAt: json['fetched_at'] != null 
          ? DateTime.parse(json['fetched_at']) 
          : DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      taxFreeAllowance: (json['tax_free_allowance'] ?? 1800000).toDouble(),
      taxBrackets: (json['tax_brackets'] as List? ?? [])
          .map((b) => TaxBracketConfig.fromJson(b))
          .toList(),
      epfEmployeeRate: (json['epf_employee_rate'] ?? 0.08).toDouble(),
      epfEmployerRate: (json['epf_employer_rate'] ?? 0.12).toDouble(),
      etfEmployerRate: (json['etf_employer_rate'] ?? 0.03).toDouble(),
      epfInterestRate: (json['epf_interest_rate'] ?? 0.09).toDouble(),
      ltvRatios: (json['ltv_ratios'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, LTVConfig.fromJson(v))),
      bankLeasingRates: (json['bank_leasing_rates'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((tk, tv) => MapEntry(int.parse(tk), tv.toDouble())))),
      fdRates: (json['fd_rates'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((tk, tv) => MapEntry(tk, tv.toDouble())))),
      personalLoanRates: (json['personal_loan_rates'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toDouble())),
    );
  }
}

class TaxBracketConfig {
  final double minAmount;
  final double maxAmount;
  final double rate;
  final String label;

  TaxBracketConfig({
    required this.minAmount,
    required this.maxAmount,
    required this.rate,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'min': minAmount,
    'max': maxAmount,
    'rate': rate,
    'label': label,
  };

  factory TaxBracketConfig.fromJson(Map<String, dynamic> json) {
    return TaxBracketConfig(
      minAmount: (json['min'] ?? 0).toDouble(),
      maxAmount: (json['max'] ?? double.infinity).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      label: json['label'] ?? '',
    );
  }
}

class LTVConfig {
  final String category;
  final double ltv;
  final String description;

  LTVConfig({
    required this.category,
    required this.ltv,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'ltv': ltv,
    'description': description,
  };

  factory LTVConfig.fromJson(Map<String, dynamic> json) {
    return LTVConfig(
      category: json['category'] ?? '',
      ltv: (json['ltv'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}