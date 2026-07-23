// File: lib/services/transaction_parser.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/transaction.dart';
import '../utils/sms_validator.dart';

class TransactionParser {
  // ==================== TIER 0: SPAM BLOCKING ====================
  
  static final List<RegExp> _spamPatterns = [
    RegExp(r'\b(OTP|verification code|one time password)\b', caseSensitive: false),
    RegExp(r'\b(prize|won|winner|congratulations|free gift)\b', caseSensitive: false),
    RegExp(r'^\d{4,8}$'),
    RegExp(r'\b(unsubscribe|STOP to|opt out)\b', caseSensitive: false),
    RegExp(r'\b(loan|credit card|personal loan).*(?:approved|eligible|offer)\b', caseSensitive: false),
  ];

  // ==================== TIER 1: CACHES ====================
  
  static final Map<String, AppTransaction> _exactMatchCache = {};
  static final Map<String, Map<String, dynamic>> _patternCache = {};

  // ==================== MAIN PARSING METHOD ====================
  
  static Future<AppTransaction?> parse(String smsBody, {required int userId, String? sender}) async {
    if (smsBody.trim().isEmpty) return null;

    // TIER 0: Block spam/OTP
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
      final transaction = _buildTransaction(data, smsBody, userId, sender: sender);
      _exactMatchCache[exactHash] = transaction;
      return transaction;
    }

    // TIER 2: Gemini API
    debugPrint('🤖 Tier 2: Calling Gemini API');
    final geminiResult = await _tryGemini(smsBody, userId, sender: sender);
    
    if (geminiResult != null) {
      _exactMatchCache[exactHash] = geminiResult;
      _patternCache[patternHash] = {
        'bankName': geminiResult.bank,
        'amount': geminiResult.amount,
        'merchant': geminiResult.merchant,
        'type': geminiResult.type,
        'category': geminiResult.category,
        'date': geminiResult.date,
        'account_mask': geminiResult.accountMask,
        'available_balance': geminiResult.availableBalance,
        'confidence': 0.95,
      };
      return geminiResult;
    }

    // TIER 3: Regex fallback
    debugPrint('⚠️ Tier 3: Gemini failed, trying regex fallback');
    final regexResult = _tryRegexFallback(smsBody, userId, sender: sender);
    
    if (regexResult != null) {
      _exactMatchCache[exactHash] = regexResult;
      debugPrint('⚠️ Regex fallback succeeded with lower confidence');
      return regexResult;
    }

    debugPrint('❌ All tiers failed to parse SMS');
    return null;
  }

  // ==================== TIER 0 IMPLEMENTATION ====================
  
  static bool _isSpamOrOTP(String sms) {
    // First check: Does it have banking keywords?
    final lower = sms.toLowerCase();
    final bankKeywords = ['credited', 'debited', 'balance', 'avl bal', 'av.bal', 'acct', 'account', 'payment', 'transfer', 'purchase', 'withdrawal', 'deposit', 'txn'];
    final hasBankKeyword = bankKeywords.any((k) => lower.contains(k));
    final hasAmount = RegExp(r'(?:LKR|Rs\.?)\s*[\d,]+\.?\d{0,2}').hasMatch(sms) ||
                      RegExp(r'(?:credited|debited)\s*(?:by\s*)?(?:LKR|Rs\.?)?\s*[\d,]+').hasMatch(sms);
    
    if (hasBankKeyword && hasAmount) return false;
    
    if (!hasBankKeyword) {
      for (var pattern in _spamPatterns) {
        if (pattern.hasMatch(sms)) {
          debugPrint('📵 Blocked: Pure OTP/Spam (no banking context)');
          return true;
        }
      }
    }
    
    return false;
  }

  // ==================== TIER 1 IMPLEMENTATION ====================
  
  static String _normalizeForCache(String sms) {
    return sms
        .replaceAll(RegExp(r'\d+\.?\d*'), '###')
        .replaceAll(RegExp(r'\d{2,}'), '###')
        .replaceAll(RegExp(r'[A-Za-z]{3,}'), 'WWW')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  // ==================== TIER 2: GEMINI ====================
  
  static Future<AppTransaction?> _tryGemini(String smsBody, int userId, {String? sender}) async {
    if (!ApiConfig.isGeminiConfigured) {
      debugPrint('⚠️ Gemini API key not configured');
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiConfig.geminiApiKey,
        systemInstruction: Content.system('''
You are a Sri Lankan bank SMS transaction extractor. Extract transaction details with HIGH accuracy.

CRITICAL RULES:
1. "date" - Extract the EXACT transaction date from the SMS. Look for patterns like:
   - "on 24-MAY" → "24-MAY"
   - "24-05-2026" → "24-MAY"  
   - "13-Jul-2026" → "13-JUL"
   If a date is clearly visible, extract it. Do NOT use "Today" unless absolutely no date is present.
2. "category" MUST be one of: "Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"
3. "type" MUST be "debit" or "credit" (lowercase)
4. "amount" must be a positive number
5. "merchant" should be the vendor/recipient name
6. "bankName" - Extract the bank name if visible in the SMS
7. "account_mask" - last 4 digits of account/card
8. "availableBalance" - remaining balance as number, null if not present

SRI LANKAN CATEGORIES:
- Keells, Cargills, Food City, Arpico → "Groceries"
- PickMe, Uber, Kangaroo → "Transport"
- Restaurant, Hotel, Cafe, KFC, Pizza → "Dining"
- Dialog, Mobitel, SLT, CEB, Water Board → "Bills & Utilities"
- Netflix, Spotify, Amazon Prime → "Recurring Payments"
- Odel, Fashion, Shopping Mall → "Shopping"

Return ONLY valid JSON:
{"amount": 3450.00, "merchant": "Keells Super", "type": "debit", "category": "Groceries", "date": "24-MAY", "bankName": "Commercial Bank", "account_mask": "4432", "availableBalance": 12700.00}

If ABSOLUTELY not a transaction: {"error": "not_transaction"}
'''),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.0,
        ),
      );

      final response = await model.generateContent([Content.text(smsBody)]);
      final String rawText = response.text ?? '{}';
      
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
        return null;
      }

      if (data['amount'] == null || data['amount'] == 0) {
        debugPrint('Gemini returned zero amount');
        return null;
      }

      return _buildTransaction(data, smsBody, userId, sender: sender);
    } catch (e) {
      debugPrint('Gemini API error: $e');
      return null;
    }
  }

  // ==================== TIER 3: REGEX FALLBACK ====================
  
  static AppTransaction? _tryRegexFallback(String sms, int userId, {String? sender}) {
    debugPrint('🔧 Attempting regex fallback...');
    
    double amount = 0.0;
    String merchant = 'Unknown';
    String type = 'debit';
    String bank = SmsValidator.getBankFromSender(sender);
    String accountMask = '';
    double? availableBalance;
    String date = 'Today';

    // Extract amount
    final amountPatterns = [
      RegExp(r'(?:LKR|Rs\.?)\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'(?:debited|credited|paid|spent)\s*(?:by\s*)?(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d{0,2})\s*(?:LKR|rupees)', caseSensitive: false),
      RegExp(r'(?:POS|ATM|TXN)\s*\d*\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'(?<!\d)(\d{1,3}(?:,\d{3})+(?:\.\d{2})?)(?!\d)'),
    ];
    
    for (var pattern in amountPatterns) {
      final matches = pattern.allMatches(sms);
      for (var match in matches) {
        final possibleAmount = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (possibleAmount != null && possibleAmount > 0) {
          final beforeMatch = sms.substring(0, match.start).toLowerCase();
          if (!beforeMatch.contains('bal') && !beforeMatch.contains('available')) {
            amount = possibleAmount;
            break;
          }
        }
      }
      if (amount > 0) break;
    }

    if (amount == 0.0) {
      debugPrint('❌ Regex could not extract amount');
      return null;
    }

    // Determine type
    if (sms.toLowerCase().contains('credit') || sms.toLowerCase().contains('deposited') || sms.toLowerCase().contains('received')) {
      type = 'credit';
    }

    // Extract merchant
    final merchantPatterns = [
      RegExp(r"(?:at|to|from)\s+([A-Za-z0-9\s&.\-']+?)(?:\s+on\s+\d|$)", caseSensitive: false),
RegExp(r"([A-Za-z0-9\s&.\-']+?)\s+as\s+(?:POS|ATM|TXN)", caseSensitive: false),
    ];
    
    for (var pattern in merchantPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        merchant = match.group(1)!.trim();
        if (merchant.length > 30) merchant = merchant.substring(0, 30);
        break;
      }
    }

    // Extract bank from body if not found from sender
    if (bank == 'Unknown Bank') {
      final lower = sms.toLowerCase();
      if (lower.contains('combank') || lower.contains('commercial')) {
        bank = 'Commercial Bank';
      } else if (lower.contains('hnb')) bank = 'HNB';
      else if (lower.contains('sampath')) bank = 'Sampath Bank';
      else if (lower.contains('boc')) bank = 'BOC';
    }

    // Extract account mask
    final maskMatch = RegExp(r'\*{0,2}(\d{4})', caseSensitive: false).firstMatch(sms);
    if (maskMatch != null) accountMask = maskMatch.group(1)!;

    // Extract balance
    final balanceMatch = RegExp(r'(?:Av\.?Bal|Balance|Bal)\s*:?\s*(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})', caseSensitive: false).firstMatch(sms);
    if (balanceMatch != null) {
      availableBalance = double.tryParse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Extract date
    final datePatterns = [
      RegExp(r'on\s+(\d{1,2}[-/][A-Za-z]{3,}(?:[-/]\d{2,4})?)', caseSensitive: false),
      RegExp(r'(\d{1,2}[-/][A-Za-z]{3,}[-/]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[-/][A-Za-z]{3,})', caseSensitive: false),
    ];
    
    for (var pattern in datePatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        date = _normalizeDateString(match.group(1)!);
        break;
      }
    }

    debugPrint('⚠️ Regex fallback: $amount at $merchant ($type) - Bank: $bank - Date: $date');

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
      aiConfidence: 0.60,
    );
  }

  // ==================== DATE NORMALIZATION ====================

  static String _normalizeDateString(String dateStr) {
    try {
      dateStr = dateStr.trim();
      
      if (RegExp(r'^\d{1,2}-[A-Za-z]{3}$').hasMatch(dateStr)) {
        return dateStr.toUpperCase();
      }
      
      if (RegExp(r'^\d{1,2}-[A-Za-z]{3}-\d{4}$').hasMatch(dateStr)) {
        return dateStr.split('-').take(2).join('-').toUpperCase();
      }
      
      final slashMatch = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?$').firstMatch(dateStr);
      if (slashMatch != null) {
        int day = int.parse(slashMatch.group(1)!);
        int month = int.parse(slashMatch.group(2)!);
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        if (month >= 1 && month <= 12) {
          return '${day.toString().padLeft(2, '0')}-${months[month - 1]}';
        }
      }
      
      return 'Today';
    } catch (e) {
      return 'Today';
    }
  }

  // ==================== HELPER METHODS ====================
  
  static AppTransaction _buildTransaction(Map<String, dynamic> data, String smsBody, int userId, {String? sender}) {
    // Get bank name - try data first, then sender
    String bankName = data['bankName']?.toString() ?? data['bank']?.toString() ?? 'Unknown Bank';
    if (bankName == 'Unknown Bank' || bankName == 'Unknown') {
      bankName = SmsValidator.getBankFromSender(sender);
    }
    
    // Get date - use extracted date if available
    String displayDate = data['date']?.toString() ?? 'Today';
    
    // Parse date for createdAt
    DateTime txDate = DateTime.now();
    if (displayDate != 'Today') {
      try {
        final months = {'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
                        'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12};
        final parts = displayDate.split('-');
        if (parts.length >= 2) {
          int day = int.parse(parts[0]);
          int month = months[parts[1].toUpperCase()] ?? DateTime.now().month;
          int year = DateTime.now().year;
          txDate = DateTime(year, month, day);
          if (txDate.isAfter(DateTime.now())) {
            txDate = DateTime(year - 1, month, day);
          }
        }
      } catch (e) {
        txDate = DateTime.now();
      }
    }

    return AppTransaction.create(
      userId: userId,
      bank: bankName,
      bankName: bankName,
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      merchant: data['merchant']?.toString() ?? 'Unknown',
      type: data['type']?.toString() ?? 'debit',
      date: displayDate,
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
      createdAt: txDate,
    );
  }

  static String _guessCategory(String merchant) {
    final lower = merchant.toLowerCase();
    if (RegExp(r'keells|cargills|food city|arpico|glomark|supermarket|grocer').hasMatch(lower)) return 'Groceries';
    if (RegExp(r'pickme|pick me|uber|bus|taxi|tuk|train|parking|highway').hasMatch(lower)) return 'Transport';
    if (RegExp(r'restaurant|hotel|cafe|bakery|pizza|kfc|mcdonalds|food|dining').hasMatch(lower)) return 'Dining';
    if (RegExp(r'ceb|water|dialog|mobitel|hutch|slt|electricity|bill|utility').hasMatch(lower)) return 'Bills & Utilities';
    if (RegExp(r'netflix|spotify|amazon|prime|youtube|apple|google|subscription').hasMatch(lower)) return 'Recurring Payments';
    if (RegExp(r'shop|mart|store|odell|fashion|mall|clothing|daraz').hasMatch(lower)) return 'Shopping';
    return 'General';
  }

  // ==================== UTILITY ====================
  
  static int get exactCacheSize => _exactMatchCache.length;
  static int get patternCacheSize => _patternCache.length;

  static void clearCache() {
    _exactMatchCache.clear();
    _patternCache.clear();
    debugPrint('🧹 All caches cleared');
  }
}