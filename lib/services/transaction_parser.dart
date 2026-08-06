// File: lib/services/transaction_parser.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/transaction.dart';
import '../utils/sms_validator.dart';
import 'on_device_parser.dart';


class TransactionParser {
  // ==================== TIER 0: SPAM BLOCKING ====================
  
  static final List<RegExp> _spamPatterns = [
    RegExp(r'\b(OTP|verification code|one time password)\b', caseSensitive: false),
    RegExp(r'\b(prize|won|winner|congratulations|free gift)\b', caseSensitive: false),
    RegExp(r'^\d{4,8}$'),
    RegExp(r'\b(unsubscribe|STOP to|opt out)\b', caseSensitive: false),
    RegExp(r'\b(loan|credit card|personal loan).*(?:approved|eligible|offer)\b', caseSensitive: false),
  ];

  static bool _isSpamOrOTP(String sms) {
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

  // ==================== TIER 1: CACHES ====================

  static final Map<String, AppTransaction> _exactMatchCache = {};

  // ==================== MAIN PARSING METHOD ====================
  
  // In TransactionParser class, update the parse method:

static Future<AppTransaction?> parse(String smsBody, {required int userId, String? sender}) async {
  if (smsBody.trim().isEmpty) return null;

  // TIER 0: Block spam/OTP
  if (_isSpamOrOTP(smsBody)) {
    debugPrint('📵 Tier 0: Blocked spam/OTP');
    return null;
  }

  // TIER 1: Try on-device parser FIRST (new!)
  debugPrint('🔍 Tier 1: On-device parser');
  final onDeviceResult = OnDeviceParser.parse(smsBody, userId: userId, sender: sender);
  
  if (onDeviceResult != null) {
    if (onDeviceResult.aiConfidence != null && onDeviceResult.aiConfidence! >= 0.70) {
      debugPrint('✅ On-device: High confidence (${(onDeviceResult.aiConfidence! * 100).toStringAsFixed(0)}%) - using result');
      return onDeviceResult;
    }
    // Low confidence - still save but mark accordingly
    debugPrint('⚠️ On-device: Low confidence - will try Gemini for verification');
  }

  // TIER 2: Try Gemini for low-confidence or failed on-device parsing
  if (ApiConfig.isGeminiConfigured) {
    debugPrint('🤖 Tier 2: Calling Gemini API for verification');
    final geminiResult = await _tryGemini(smsBody, userId, sender: sender);
    
    if (geminiResult != null) {
      // Use Gemini result (higher accuracy)
      _exactMatchCache[smsBody.trim().toLowerCase()] = geminiResult;
      return geminiResult;
    }
  }

  // Return on-device result as fallback (even if low confidence)
  if (onDeviceResult != null) {
    debugPrint('📦 Using on-device result as fallback');
    return onDeviceResult;
  }

  // TIER 3: Regex fallback
  debugPrint('⚠️ Tier 3: Regex fallback');
  final regexResult = _tryRegexFallback(smsBody, userId, sender: sender);
  return regexResult;
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
You are a Sri Lankan bank SMS transaction extractor. Extract ALL details accurately.

FIELDS TO EXTRACT:
- "amount": LKR amount as a number (0 if foreign currency with no LKR amount shown)
- "merchant": vendor/recipient name (clean, without reference codes or trailing numbers)
- "type": "debit" or "credit" (lowercase only)
- "category": see list below
- "date": exact date in DD-MMM format (e.g. "03-AUG"). Never use "Today" if a date is visible.
- "bankName": bank name from SMS or sender
- "account_mask": last 2-4 digits of account/card number
- "accountType": "Savings", "Current", or "Credit Card"
- "availableBalance": balance after transaction as number, null if not shown
- "foreignCurrency": 3-letter currency code if transaction is in foreign currency (e.g. "USD"), null otherwise
- "foreignAmount": amount in foreign currency as number, null if LKR transaction

DATE RULES:
- "on 28/07/26" → "28-JUL"
- "(03-Aug-2026 ...)" → "03-AUG"
- "Date:26.07.26" → "26-JUL"

TYPE RULES:
- "credited to Ac No" → "credit"
- "debited to Ac No" → "debit"
- "Transaction Approved on your Card" → "debit"
- "Reason:MB BillPmt/Credit Card Pmt" → "debit"
- "Reason:S/O FROM ..." → "credit"
- "Thank you for your payment" → "credit" (card payment acknowledgement)

MERCHANT RULES:
- "VC : **6302 :UBER EATS 852 (Apprx)" → merchant is "Uber Eats" (ignore trailing reference numbers)
- "Location:ANTHROPIC* CLAUDE SUB, US" → merchant is "Anthropic Claude Sub"
- "Reason:MB BillPmt/Credit Card Pmt Non HNB/552474..." → merchant is "Credit Card Payment"
- "Reason:MB:Subscriptions" → merchant is "Subscriptions" (a transfer label)
- "Reason:S/O FROM WELIKALA J P D" → merchant is "Welikala J P D"
- "at FOOD STUDIO PVT LTD" → merchant is "Food Studio"

CATEGORIES (pick exactly one):
- "Groceries": Keells, Cargills, Food City, Arpico, Spar, Sathosa
- "Transport": PickMe, Uber (rides only), Kangaroo, fuel, parking, highway
- "Dining": Uber Eats, UberEats, restaurants, cafes, KFC, Pizza Hut, food delivery
- "Bills & Utilities": Dialog, Mobitel, SLT, CEB, water, electricity, bill payments
- "Recurring Payments": Netflix, Spotify, Amazon, Apple, Google, Adobe, Anthropic, subscriptions
- "Shopping": Odel, malls, clothing, Daraz, online shopping
- "Transfers": credit card payments, bank transfers, standing orders, MB transfers
- "Income": salary, credited amounts, interest, standing orders received
- "General": anything else

Return ONLY valid JSON. Examples:
{"amount": 5569.92, "merchant": "Uber Eats", "type": "debit", "category": "Dining", "date": "03-AUG", "bankName": "HNB", "account_mask": "6302", "accountType": "Savings", "availableBalance": 12763.45, "foreignCurrency": null, "foreignAmount": null}
{"amount": 0, "merchant": "Anthropic Claude Sub", "type": "debit", "category": "Recurring Payments", "date": "03-AUG", "bankName": "HNB", "account_mask": "7603", "accountType": "Savings", "availableBalance": 9147.66, "foreignCurrency": "USD", "foreignAmount": 20.0}
{"amount": 42070.00, "merchant": "Credit Card Payment", "type": "debit", "category": "Transfers", "date": "02-AUG", "bankName": "HNB", "account_mask": "XX34", "accountType": "Savings", "availableBalance": 63684.57, "foreignCurrency": null, "foreignAmount": null}

If not a transaction: {"error": "not_transaction"}
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

      // Allow amount == 0 only for foreign currency transactions
      final isFx = data['foreignCurrency'] != null && data['foreignCurrency'] != 'null';
      if ((data['amount'] == null || data['amount'] == 0) && !isFx) {
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

    // Determine type — match same logic as on_device_parser to avoid false positives on "Credit Card Pmt"
    final lower = sms.toLowerCase();
    if (RegExp(r'credited\s+to|deposited|salary\s+credit').hasMatch(lower)) {
      type = 'credit';
    } else if (RegExp(r'\bcredited\b').hasMatch(lower)) {
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
      } else if (lower.contains('hnb')) { bank = 'HNB'; }
      else if (lower.contains('sampath')) { bank = 'Sampath Bank'; }
      else if (lower.contains('boc')) { bank = 'BOC'; }
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

    if (kDebugMode) debugPrint('⚠️ Regex fallback: $amount at $merchant ($type) - Bank: $bank - Date: $date');

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

    final fxCurrency = data['foreignCurrency']?.toString();
    final fxAmount = data['foreignAmount'] != null
        ? double.tryParse(data['foreignAmount'].toString())
        : null;

    return AppTransaction.create(
      userId: userId,
      bank: bankName,
      bankName: bankName,
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      merchant: data['merchant']?.toString() ?? 'Unknown',
      type: data['type']?.toString() ?? 'debit',
      date: displayDate,
      category: data['category']?.toString() ?? 'General',
      accountType: data['accountType']?.toString() ?? 'Savings',
      accountMask: data['account_mask']?.toString() ?? '',
      availableBalance: data['availableBalance'] != null
          ? double.tryParse(data['availableBalance'].toString())
          : null,
      foreignCurrency: (fxCurrency == null || fxCurrency == 'null') ? null : fxCurrency,
      foreignAmount: fxAmount,
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

  static void clearCache() {
    _exactMatchCache.clear();
    debugPrint('🧹 All caches cleared');
  }
}