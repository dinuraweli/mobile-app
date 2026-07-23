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
    
    // Layer 2: Fallback to hardcoded rates
    debugPrint('⚠️ Using hardcoded exchange rate fallbacks for $currency');
    final fallback = _fallbackRates[currency] ?? _fallbackRates['USD']!;
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