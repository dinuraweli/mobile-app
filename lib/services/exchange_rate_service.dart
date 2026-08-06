// File: lib/services/exchange_rate_service.dart
import 'package:flutter/foundation.dart';
import 'financial_config_service.dart';

class ExchangeRateService {
  static const List<String> currencies = ['USD', 'EUR', 'GBP', 'AUD', 'JPY', 'CAD', 'AED', 'CHF'];

  static const List<String> banks = [
    'Commercial Bank', 'HNB', 'Sampath Bank', 'BOC', 'NDB', 'Peoples Bank', 'Seylan Bank',
  ];

  // ==================== HARDCODED FALLBACK RATES ====================
  // Used only when Firebase and cache both fail
  
  static const Map<String, Map<String, Map<String, double>>> _fallbackRates = {
    'USD': {
      'Commercial Bank': {'buying': 305.50, 'selling': 311.60},
      'HNB': {'buying': 306.20, 'selling': 312.30},
      'Sampath Bank': {'buying': 305.80, 'selling': 311.70},
      'BOC': {'buying': 306.50, 'selling': 312.60},
      'NDB': {'buying': 305.90, 'selling': 311.80},
      'Peoples Bank': {'buying': 306.00, 'selling': 312.00},
      'Seylan Bank': {'buying': 306.30, 'selling': 312.40},
    },
    'EUR': {
      'Commercial Bank': {'buying': 335.20, 'selling': 341.90},
      'HNB': {'buying': 336.00, 'selling': 342.70},
      'Sampath Bank': {'buying': 335.50, 'selling': 342.20},
      'BOC': {'buying': 336.50, 'selling': 343.20},
      'NDB': {'buying': 335.80, 'selling': 342.50},
      'Peoples Bank': {'buying': 336.20, 'selling': 342.90},
      'Seylan Bank': {'buying': 336.80, 'selling': 343.50},
    },
    'GBP': {
      'Commercial Bank': {'buying': 390.80, 'selling': 398.60},
      'HNB': {'buying': 391.50, 'selling': 399.30},
      'Sampath Bank': {'buying': 391.00, 'selling': 398.80},
      'BOC': {'buying': 392.00, 'selling': 399.80},
      'NDB': {'buying': 391.20, 'selling': 399.00},
      'Peoples Bank': {'buying': 391.80, 'selling': 399.60},
      'Seylan Bank': {'buying': 392.50, 'selling': 400.30},
    },
    'AUD': {
      'Commercial Bank': {'buying': 193.20, 'selling': 197.80},
      'HNB': {'buying': 193.60, 'selling': 198.20},
      'Sampath Bank': {'buying': 193.30, 'selling': 197.90},
      'BOC': {'buying': 193.80, 'selling': 198.40},
      'NDB': {'buying': 193.40, 'selling': 198.00},
      'Peoples Bank': {'buying': 193.50, 'selling': 198.10},
      'Seylan Bank': {'buying': 193.70, 'selling': 198.30},
    },
    'CAD': {
      'Commercial Bank': {'buying': 217.40, 'selling': 222.50},
      'HNB': {'buying': 217.80, 'selling': 222.90},
      'Sampath Bank': {'buying': 217.50, 'selling': 222.60},
      'BOC': {'buying': 218.00, 'selling': 223.10},
      'NDB': {'buying': 217.60, 'selling': 222.70},
      'Peoples Bank': {'buying': 217.70, 'selling': 222.80},
      'Seylan Bank': {'buying': 217.90, 'selling': 223.00},
    },
    'JPY': {
      'Commercial Bank': {'buying': 1.960, 'selling': 2.020},
      'HNB': {'buying': 1.965, 'selling': 2.025},
      'Sampath Bank': {'buying': 1.962, 'selling': 2.022},
      'BOC': {'buying': 1.968, 'selling': 2.028},
      'NDB': {'buying': 1.963, 'selling': 2.023},
      'Peoples Bank': {'buying': 1.964, 'selling': 2.024},
      'Seylan Bank': {'buying': 1.966, 'selling': 2.026},
    },
    'AED': {
      'Commercial Bank': {'buying': 83.10, 'selling': 85.20},
      'HNB': {'buying': 83.30, 'selling': 85.40},
      'Sampath Bank': {'buying': 83.15, 'selling': 85.25},
      'BOC': {'buying': 83.40, 'selling': 85.50},
      'NDB': {'buying': 83.20, 'selling': 85.30},
      'Peoples Bank': {'buying': 83.25, 'selling': 85.35},
      'Seylan Bank': {'buying': 83.35, 'selling': 85.45},
    },
    'CHF': {
      'Commercial Bank': {'buying': 338.50, 'selling': 346.20},
      'HNB': {'buying': 339.20, 'selling': 346.90},
      'Sampath Bank': {'buying': 338.70, 'selling': 346.40},
      'BOC': {'buying': 339.50, 'selling': 347.20},
      'NDB': {'buying': 338.90, 'selling': 346.60},
      'Peoples Bank': {'buying': 339.00, 'selling': 346.70},
      'Seylan Bank': {'buying': 339.30, 'selling': 347.00},
    },
  };

  // ==================== GET TODAY'S RATES ====================

  static Future<ExchangeRateData> getRates(String currency) async {
    // Layer 1: Try Firebase Remote Config
    final configService = FinancialConfigService();
    final remoteData = await configService.getExchangeRates();
    
    if (remoteData != null && remoteData['rates'] != null) {
      final rates = remoteData['rates'][currency];
      if (rates != null) {
        final bankRates = <String, BankRate>{};
        rates.forEach((bank, data) {
          bankRates[bank] = BankRate(
            buying: (data['buying'] as num).toDouble(),
            selling: (data['selling'] as num).toDouble(),
          );
        });
        return ExchangeRateData(
          bankRates: bankRates,
          source: 'remote',
          version: remoteData['version'] ?? 'unknown',
          updatedAt: remoteData['updated_at'] ?? '',
        );
      }
    }
    
    // Layer 2: Fallback to hardcoded rates (all 8 currencies now covered)
    debugPrint('⚠️ Using hardcoded exchange rate fallbacks for $currency');
    final fallback = _fallbackRates[currency];
    if (fallback == null) {
      // Should never happen now that all currencies are covered, but safe guard
      return ExchangeRateData(bankRates: {}, source: 'fallback', version: 'built-in', updatedAt: '');
    }
    final bankRates = <String, BankRate>{};
    fallback.forEach((bank, data) {
      bankRates[bank] = BankRate(
        buying: data['buying']!,
        selling: data['selling']!,
      );
    });
    
    return ExchangeRateData(
      bankRates: bankRates,
      source: 'fallback',
      version: 'built-in',
      updatedAt: '',
    );
  }
}

// ==================== DATA MODELS ====================

class BankRate {
  final double buying;
  final double selling;
  BankRate({required this.buying, required this.selling});
}

class ExchangeRateData {
  final Map<String, BankRate> bankRates;
  final String source;
  final String version;
  final String updatedAt;
  
  ExchangeRateData({
    required this.bankRates,
    required this.source,
    required this.version,
    required this.updatedAt,
  });
  
  bool get isLiveData => source == 'remote';
  bool get isFallback => source == 'fallback';
}