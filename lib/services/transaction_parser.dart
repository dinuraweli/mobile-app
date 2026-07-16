// File: lib/services/transaction_parser.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/transaction.dart';

class TransactionParser {
  // ==================== TIER 0: SPAM BLOCKING ====================
  
  static final List<RegExp> _spamPatterns = [
    RegExp(r'\b(OTP|verification code|one time password)\b', caseSensitive: false),
    RegExp(r'\b(prize|won|winner|congratulations|free gift)\b', caseSensitive: false),
    RegExp(r'^\d{4,8}$'),
    RegExp(r'\b(unsubscribe|STOP to|opt out)\b', caseSensitive: false),
    RegExp(r'\b(loan|credit card|personal loan).*(?:approved|eligible|offer)\b', caseSensitive: false),
  ];

  // ==================== TIER 1: EXACT MATCH CACHE ====================
  
  // Cache stores: original SMS hash → parsed result
  static final Map<String, AppTransaction> _exactMatchCache = {};
  
  // Similar pattern cache: normalized SMS → parsed result
  static final Map<String, Map<String, dynamic>> _patternCache = {};

  // ==================== MAIN PARSING METHOD ====================
  
  static Future<AppTransaction?> parse(String smsBody, {required int userId}) async {
    if (smsBody.trim().isEmpty) return null;

    // TIER 0: Block spam/OTP immediately
    if (_isSpamOrOTP(smsBody)) {
      debugPrint('📵 Tier 0: Blocked spam/OTP');
      return null;
    }

    // TIER 1: Check exact match cache
    final exactHash = '${userId}_${smsBody.trim().toLowerCase()}';
    if (_exactMatchCache.containsKey(exactHash)) {
      debugPrint('💾 Tier 1: Exact cache hit');
      return _exactMatchCache[exactHash];
    }

    // Check similar pattern cache
    final patternHash = '${userId}_${_normalizeForCache(smsBody)}';
    if (_patternCache.containsKey(patternHash)) {
      debugPrint('💾 Tier 1: Pattern cache hit');
      final data = _patternCache[patternHash]!;
      final transaction = _buildTransaction(data, smsBody, userId);
      _exactMatchCache[exactHash] = transaction;
      return transaction;
    }

    // TIER 2: PRIMARY - Gemini API
    debugPrint('🤖 Tier 2: Calling Gemini API');
    final geminiResult = await _tryGemini(smsBody, userId);
    
    if (geminiResult != null) {
      // Cache for future
      _exactMatchCache[exactHash] = geminiResult;
      _patternCache[patternHash] = {
        'bank': geminiResult.bank,
        'amount': geminiResult.amount,
        'merchant': geminiResult.merchant,
        'type': geminiResult.type,
        'category': geminiResult.category,
        'account_mask': geminiResult.accountMask,
        'available_balance': geminiResult.availableBalance,
        'source': 'gemini',
        'confidence': 0.95,
      };
      return geminiResult;
    }

    // TIER 3: FALLBACK - Regex (only if Gemini completely fails)
    debugPrint('⚠️ Tier 3: Gemini failed, trying regex fallback');
    final regexResult = _tryRegexFallback(smsBody, userId);
    
    if (regexResult != null) {
      // Still cache it, but mark as lower confidence
      _exactMatchCache[exactHash] = regexResult;
      debugPrint('⚠️ Regex fallback succeeded with lower confidence');
      return regexResult;
    }

    debugPrint('❌ All tiers failed to parse SMS');
    return null;
  }

  // ==================== TIER 0 IMPLEMENTATION ====================
  
  static bool _isSpamOrOTP(String sms) {
    return _spamPatterns.any((p) => p.hasMatch(sms));
  }

  // ==================== TIER 1 IMPLEMENTATION ====================
  
  static String _normalizeForCache(String sms) {
    // Replace variable parts with placeholders
    return sms
        .replaceAll(RegExp(r'\d+\.?\d*'), '###')       // amounts
        .replaceAll(RegExp(r'\d{2,}'), '###')            // dates, account numbers
        .replaceAll(RegExp(r'[A-Za-z]{3,}'), 'WWW')      // month names
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  // ==================== TIER 2: GEMINI (PRIMARY) ====================
  
  static Future<AppTransaction?> _tryGemini(String smsBody, int userId) async {
    if (!ApiConfig.isGeminiConfigured) {
      debugPrint('⚠️ Gemini API key not configured, skipping to regex');
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: ApiConfig.geminiApiKey,
        systemInstruction: Content.system('''
You are a Sri Lankan bank SMS transaction extractor. Your job is to extract financial transactions from bank alert messages.

IMPORTANT: Almost ALL SMS messages from banks about account activity ARE transactions. Only reject obvious spam, promotional offers, or pure informational messages.

EXTRACT if the SMS contains ANY of:
- Debit/credit/payment/purchase/transfer information
- Amount in LKR or Rs.
- Account activity (money in or out)

ONLY REJECT if the SMS is:
- A promotional offer ("Get a loan at 8%", "Special offer", etc.)
- Pure information with NO monetary amount ("Your statement is ready", "New branch opened")
- An advertisement

EXTRACTION RULES:
1. "category" MUST be one of: "Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"
2. "type" MUST be "debit" or "credit" (lowercase)
   - Money LEAVING account = "debit" (purchases, payments, withdrawals, transfers out)
   - Money ENTERING account = "credit" (deposits, salary, transfers in, refunds)
3. "amount" must be a positive number (extract the transaction amount, not the balance)
4. "merchant" should be the vendor/recipient/sender name
   - For POS transactions, extract the merchant name
   - For transfers, indicate "Transfer to [name]" or "Transfer from [name]"
   - For ATM withdrawals, use "ATM Withdrawal"
   - For bill payments, use the biller name (Dialog, CEB, etc.)
5. "date" in DD-MMM format if available, otherwise "Today"
6. "account_mask" - last 4 digits of account/card if visible
7. "availableBalance" - the remaining balance as a number (not string)

SRI LANKAN MERCHANT CATEGORIZATION:
- Keells, Cargills, Food City, Arpico, Glomark, Supermarket → "Groceries"
- PickMe, Uber, Kangaroo, Bus, Train, Parking, Highway → "Transport"
- Restaurant, Hotel, Cafe, Pizza, KFC, McDonalds, Food Court → "Dining"
- Dialog, Mobitel, Hutch, SLT, CEB, Water Board, LankaPay → "Bills & Utilities"
- Netflix, Spotify, Amazon Prime, YouTube Premium → "Recurring Payments"
- Odel, Fashion, Cool Planet, Shopping Mall → "Shopping"

Return ONLY a JSON object (no markdown, no explanation):
{"amount": 3450.00, "merchant": "Keells Super", "type": "debit", "category": "Groceries", "date": "24-MAY", "bank": "Commercial Bank", "account_mask": "4432", "availableBalance": 12700.00}

If ABSOLUTELY no transaction can be found (no amount, no monetary activity):
{"error": "not_transaction"}
'''),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.0,
        ),
      );

      final response = await model.generateContent([Content.text(smsBody)]);
      final String rawText = response.text ?? '{}';
      
      // Clean response
      String cleanJson = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      if (cleanJson.startsWith('[')) {
        cleanJson = cleanJson.substring(1, cleanJson.length - 1).trim();
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);

      if (data.containsKey('error')) {
        debugPrint('Gemini rejected: ${data['error']}');
        debugPrint('SMS content: ${smsBody.substring(0, smsBody.length > 100 ? 100 : smsBody.length)}...');
        return null;
      }

      if (data.containsKey('error')) {
  debugPrint('🔍 Gemini rejected SMS: $smsBody');  // ← ADD THIS
  debugPrint('Gemini rejected: ${data['error']}');
  return null;
}

      if (data['amount'] == null || data['amount'] == 0) {
        debugPrint('Gemini returned zero amount for SMS: ${smsBody.substring(0, 100)}...');
        return null;
      }

      return _buildTransaction(data, smsBody, userId);
    } catch (e) {
      debugPrint('Gemini API error: $e');
      return null;
    }
  }

  // ==================== TIER 3: REGEX FALLBACK ====================
  
  static AppTransaction? _tryRegexFallback(String sms, int userId) {
    debugPrint('🔧 Attempting regex fallback...');
    
    // Only use regex when Gemini completely fails (network error, API down, etc.)
    // This should happen rarely (< 2% of cases)
    
    double amount = 0.0;
    String merchant = 'Unknown';
    String type = 'debit';
    String bank = 'Unknown Bank';
    String accountMask = '';
    double? availableBalance;
    String date = 'Today';

    // Try to extract amount (most critical field)
    final amountPatterns = [
      // HNB format: "LKR 2,500.00 debited"
      RegExp(r'(?:LKR|Rs\.?)\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Standard: "debited by LKR 500"
      RegExp(r'(?:debited|credited|paid|spent|purchased)\s*(?:by\s*)?(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Amount before LKR: "2,500.00 LKR"
      RegExp(r'([\d,]+\.?\d{0,2})\s*(?:LKR|rupees)', caseSensitive: false),
      // POS transaction amount: "POS 123456 2,500.00"
      RegExp(r'(?:POS|ATM|TXN)\s*\d*\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Any number that looks like currency (3+ digits with optional decimals)
      RegExp(r'(?<!\d)(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)(?!\d)'),
    ];
    
    for (var pattern in amountPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        break;
      }
    }

    if (amount == 0.0) {
      debugPrint('❌ Regex could not extract amount');
      return null;
    }

    // Determine type
    if (sms.toLowerCase().contains('credit') || 
        sms.toLowerCase().contains('deposited') ||
        sms.toLowerCase().contains('received')) {
      type = 'credit';
    }

    // Try to extract merchant
    final merchantPatterns = [
      // "at MERCHANT on DATE"
      RegExp(r"(?:at|to|from)\s+([A-Za-z0-9\s&.'-]+?)(?:\s+on\s+\d|$)", caseSensitive: false),
      // "MERCHANT as POS TXN"
      RegExp(r"([A-Za-z0-9\s&.'-]+?)\s+as\s+(?:POS|ATM|TXN)", caseSensitive: false),
      // "to MERCHANT" at end
      RegExp(r"(?:to|at)\s+([A-Za-z0-9\s&.'-]+?)$", caseSensitive: false),
      // HNB format: extract merchant from description
      RegExp(r"(?:purchase|payment|transaction)\s+(?:at|to|from)?\s*([A-Za-z0-9\s&.'-]+?)(?:\s+on\s+\d|\s+as\s+POS|$)", caseSensitive: false),
    ];
    
    for (var pattern in merchantPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        merchant = match.group(1)!.trim();
        // Clean up merchant name
        merchant = merchant.replaceAll(RegExp(r'\s+'), ' ');
        if (merchant.length > 30) merchant = merchant.substring(0, 30);
        break;
      }
    }

    // Try to identify bank
    if (sms.toLowerCase().contains('combank') || sms.toLowerCase().contains('commercial')) {
      bank = 'Commercial Bank';
    } else if (sms.toLowerCase().contains('hnb')) {
      bank = 'HNB';
    } else if (sms.toLowerCase().contains('sampath')) {
      bank = 'Sampath Bank';
    } else if (sms.toLowerCase().contains('boc')) {
      bank = 'BOC';
    }

    // Try to extract account mask (last 4 digits)
    final maskPattern = RegExp(r'(?:A/C|Acct|Account|Card)\s*\*{0,2}(\d{4})', caseSensitive: false);
    final maskMatch = maskPattern.firstMatch(sms);
    if (maskMatch != null) {
      accountMask = maskMatch.group(1)!;
    }

    // Try to extract balance
    final balancePattern = RegExp(r'(?:Bal|Balance|Avl Bal)\s*(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})', caseSensitive: false);
    final balanceMatch = balancePattern.firstMatch(sms);
    if (balanceMatch != null) {
      availableBalance = double.tryParse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Try to extract date
    final datePattern = RegExp(r'(\d{1,2}[-/][A-Za-z]{3,})', caseSensitive: false);
    final dateMatch = datePattern.firstMatch(sms);
    if (dateMatch != null) {
      date = dateMatch.group(1)!;
    }

    debugPrint('⚠️ Regex fallback: $amount at $merchant ($type) - LOW CONFIDENCE');

    return AppTransaction.create(
      userId: userId,
      bank: bank,
      bankName: bank,
      amount: amount,
      merchant: merchant,
      type: type,
      date: date,
      category: _guessCategory(merchant),
      accountMask: accountMask,
      availableBalance: availableBalance,
      source: 'sms_regex_fallback',
      smsRawText: sms,
      aiConfidence: 0.60, // Mark as low confidence
    );
  }

  // ==================== HELPER METHODS ====================
  
  static AppTransaction _buildTransaction(Map<String, dynamic> data, String smsBody, int userId) {
    return AppTransaction.create(
      userId: userId,
      bank: data['bank']?.toString() ?? 'Unknown',
      bankName: data['bankName']?.toString() ?? data['bank']?.toString() ?? 'Unknown',
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      merchant: data['merchant']?.toString() ?? 'Unknown',
      type: data['type']?.toString() ?? 'debit',
      date: data['date']?.toString() ?? 'Today',
      category: data['category']?.toString() ?? 'General',
      accountMask: data['account_mask']?.toString() ?? '',
      availableBalance: data['availableBalance'] != null
          ? double.tryParse(data['availableBalance'].toString())
          : null,
      source: 'sms',
      smsRawText: smsBody,
      aiConfidence: data['confidence'] != null
          ? double.tryParse(data['confidence'].toString())
          : 0.95,
    );
  }

  static String _guessCategory(String merchant) {
    final lower = merchant.toLowerCase();
    
    // Groceries
    if (RegExp(r'keells|cargills|food city|arpico|glomark|supermarket|grocer').hasMatch(lower)) {
      return 'Groceries';
    }
    // Transport
    if (RegExp(r'pickme|pick me|uber|bus|taxi|tuk|train|parking|highway').hasMatch(lower)) {
      return 'Transport';
    }
    // Dining
    if (RegExp(r'restaurant|hotel|cafe|bakery|pizza|kfc|mcdonalds|food|dining|eat').hasMatch(lower)) {
      return 'Dining';
    }
    // Bills & Utilities
    if (RegExp(r'ceb|water|dialog|mobitel|hutch|slt|electricity|bill|utility').hasMatch(lower)) {
      return 'Bills & Utilities';
    }
    // Recurring Payments
    if (RegExp(r'netflix|spotify|amazon|prime|youtube|apple|google|subscription').hasMatch(lower)) {
      return 'Recurring Payments';
    }
    // Shopping
    if (RegExp(r'shop|mart|store|odell|fashion|mall|clothing|daraz').hasMatch(lower)) {
      return 'Shopping';
    }
    
    return 'General';
  }

  // ==================== UTILITY METHODS ====================
  
  static int get exactCacheSize => _exactMatchCache.length;
  static int get patternCacheSize => _patternCache.length;

  static void clearCache() {
    _exactMatchCache.clear();
    _patternCache.clear();
    debugPrint('🧹 All caches cleared');
  }

  static Map<String, int> getStats() {
    return {
      'exact_cache_entries': _exactMatchCache.length,
      'pattern_cache_entries': _patternCache.length,
    };
  }
}