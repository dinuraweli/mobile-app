// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== READ RATES ====================

  /// Get all financial rates from Firestore
  Future<Map<String, dynamic>?> getRates() async {
    try {
      final doc = await _firestore
          .collection('financial_config')
          .doc('rates')
          .get();

      if (doc.exists) {
        debugPrint('📡 Rates fetched from Firestore');
        return doc.data();
      }
      debugPrint('⚠️ No rates document found in Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Firestore read error: $e');
      return null;
    }
  }

  /// Get exchange rates
  Future<Map<String, dynamic>?> getExchangeRates() async {
    try {
      final doc = await _firestore
          .collection('financial_config')
          .doc('exchange_rates')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Exchange rates read error: $e');
      return null;
    }
  }

  // ==================== WRITE RATES (Admin) ====================

  /// Save FD rates to Firestore
  Future<void> saveFDRates(Map<String, Map<String, double>> rates) async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({'fd_rates': _convertMapForFirestore(rates)}, SetOptions(merge: true));
    debugPrint('✅ FD rates saved to Firestore');
  }

  /// Save tax brackets
  Future<void> saveTaxBrackets(List<Map<String, dynamic>> brackets, double taxFreeAllowance) async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({
          'tax_brackets': brackets,
          'tax_free_allowance': taxFreeAllowance,
        }, SetOptions(merge: true));
    debugPrint('✅ Tax brackets saved to Firestore');
  }

  /// Save LTV ratios
  Future<void> saveLTVRatios(Map<String, Map<String, dynamic>> ltvData) async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({'ltv_ratios': ltvData}, SetOptions(merge: true));
    debugPrint('✅ LTV ratios saved to Firestore');
  }

  /// Save bank leasing rates
  Future<void> saveLeasingRates(Map<String, Map<String, double>> rates) async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({'bank_leasing_rates': _convertMapForFirestore(rates)}, SetOptions(merge: true));
    debugPrint('✅ Leasing rates saved to Firestore');
  }

  /// Save loan rates
  Future<void> saveLoanRates(Map<String, Map<String, double>> rates) async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({'loan_rates': _convertMapForFirestore(rates)}, SetOptions(merge: true));
    debugPrint('✅ Loan rates saved to Firestore');
  }

  /// Save exchange rates
  Future<void> saveExchangeRates(Map<String, dynamic> rates) async {
    await _firestore
        .collection('financial_config')
        .doc('exchange_rates')
        .set(rates);
    debugPrint('✅ Exchange rates saved to Firestore');
  }

  /// Publish timestamp (triggers app refresh)
  Future<void> publishRates() async {
    await _firestore
        .collection('financial_config')
        .doc('rates')
        .set({
          'published_at': FieldValue.serverTimestamp(),
          'version': DateTime.now().toIso8601String().substring(0, 10),
        }, SetOptions(merge: true));
    debugPrint('🚀 Rates published!');
  }

  // Helper to convert nested maps for Firestore
  Map<String, dynamic> _convertMapForFirestore(Map<String, Map<String, double>> data) {
    return data.map((key, value) => MapEntry(key, value.map((k, v) => MapEntry(k.toString(), v))));
  }
}