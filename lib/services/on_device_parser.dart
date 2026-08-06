// File: lib/services/on_device_parser.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../utils/sms_validator.dart';
import 'merchant_database.dart';

class OnDeviceParser {
  // ==================== CACHE ====================

  static final Map<String, AppTransaction> _exactCache = {};

  // ==================== AMOUNT PATTERNS ====================

  static final List<RegExp> _amountPatterns = [
    RegExp(r'(?:LKR|Rs\.?)\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'for\s*(?:LKR|Rs\.?)\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'(?:debited|credited|paid|spent)\s*(?:by\s*)?(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    RegExp(r'([\d,]+\.?\d{0,2})\s*(?:LKR|rupees)', caseSensitive: false),
    RegExp(r'(?<!\d)(\d{1,3}(?:,\d{3})+(?:\.\d{2})?)(?!\d)'),
    RegExp(r'(\d+\.\d{2})'),
  ];

  // ==================== DATE PATTERNS ====================

  static final List<RegExp> _datePatterns = [
    // "(03-Aug-2026 06:05:41 AM)" — HNB VC timestamp in parens
    RegExp(r'\((\d{1,2}-[A-Za-z]{3}-\d{4})\s', caseSensitive: false),
    // "on 28/07/26"
    RegExp(r'on\s+(\d{1,2}[-/][A-Za-z]{3,}(?:[-/]\d{2,4})?)', caseSensitive: false),
    // "24-MAY-2026"
    RegExp(r'(\d{1,2}[-/][A-Za-z]{3,}[-/]\d{2,4})', caseSensitive: false),
    // "Date:26.07.26" — HNB ALERT format
    RegExp(r'Date:(\d{2}[./]\d{2}[./]\d{2,4})', caseSensitive: false),
    // "28/07/26" or "28/07/2026"
    RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})', caseSensitive: false),
  ];

  // ==================== SPECIALISED PATTERNS ====================

  // HNB VC (Virtual Card/Contactless): "VC : **6302 :UBER EATS 852 (Apprx)"
  static final RegExp _hnbVcMerchantPattern = RegExp(
    r'VC\s*:\s*\*+\d+\s*:([\w\s&\-\.]+?)\s*(?:\d{3,}|\(Apprx\)|LKR)',
    caseSensitive: false,
  );

  // HNB Location field: "Location:MONGOLIAN SEA FOOD CUISIN, LK"
  static final RegExp _locationPattern = RegExp(
    r'Location:([^,\n]+)',
    caseSensitive: false,
  );

  // Credit card transaction: "your Card 552474******5706"
  static final RegExp _creditCardTxnPattern = RegExp(
    r'(?:your\s+)?[Cc]ard\s+\d{6,}\*+(\d{4})',
  );

  // Reason field
  static final RegExp _reasonPattern = RegExp(
    r'Reason:([^\n*]+)',
    caseSensitive: false,
  );

  // Account mask — asterisk format: "***7603" → "7603"
  static final RegExp _asteriskMaskPattern = RegExp(r'\*{2,}(\d{2,4})');

  // Account mask — XXXXX format: "09302XXXXX34" → "34"
  static final RegExp _xMaskPattern = RegExp(r'\d+[Xx]{3,}(\d{2,4})');

  // Foreign currency: "Amount(Approx.):20.00 USD"
  static final RegExp _foreignAmountPattern = RegExp(
    r'Amount(?:[^:]*)?:\s*([\d,]+\.?\d{0,2})\s+([A-Z]{3})\b',
  );

  // ==================== BALANCE PATTERN ====================

  static final RegExp _balancePattern = RegExp(
    r'(?:Av\.?Bal|Balance|Bal|Available Bal)\s*:?\s*(?:LKR|Rs\.?)?\s*([\d,]+\.?\d{0,2})',
    caseSensitive: false,
  );

  // ==================== MAIN PARSE METHOD ====================

  static AppTransaction? parse(String smsBody, {required int userId, String? sender}) {
    if (smsBody.trim().isEmpty) return null;

    final cacheKey = smsBody.trim().toLowerCase();
    if (_exactCache.containsKey(cacheKey)) {
      debugPrint('📦 On-device: Cache hit');
      return _exactCache[cacheKey];
    }

    debugPrint('🔍 On-device: Parsing SMS');

    // --- STEP 1: Detect foreign currency ---
    String? foreignCurrency;
    double? foreignAmount;
    final fxMatch = _foreignAmountPattern.firstMatch(smsBody);
    if (fxMatch != null) {
      final currency = fxMatch.group(2)!;
      if (currency != 'LKR') {
        foreignAmount = double.tryParse(fxMatch.group(1)!.replaceAll(',', ''));
        foreignCurrency = currency;
      }
    }

    // --- STEP 2: Extract LKR amount ---
    // For foreign currency SMS the LKR debit amount is not shown; set to 0
    double amount = foreignCurrency != null ? 0.0 : _extractAmount(smsBody);
    if (amount <= 0 && foreignCurrency == null) {
      debugPrint('❌ On-device: No amount found');
      return null;
    }

    // --- STEP 3: Detect credit card transaction ---
    String accountType = 'Savings';
    String accountMask = '';
    bool isCreditCard = false;

    final ccMatch = _creditCardTxnPattern.firstMatch(smsBody);
    if (ccMatch != null) {
      accountType = 'Credit Card';
      accountMask = ccMatch.group(1)!;
      isCreditCard = true;
    }

    // --- STEP 4: Determine transaction type ---
    String type = _determineType(smsBody);

    // --- STEP 5: Process Reason field ---
    String merchant = 'Unknown';
    String category = 'General';
    bool merchantDetermined = false;

    final reasonMatch = _reasonPattern.firstMatch(smsBody);
    if (reasonMatch != null) {
      final reason = reasonMatch.group(1)!.trim();
      final reasonLower = reason.toLowerCase();

      // Credit Card Payment settlement
      if (RegExp(r'credit\s*card\s*pmt|cc\s*pmt', caseSensitive: false).hasMatch(reason)) {
        merchant = 'Credit Card Payment';
        category = 'Transfers';
        type = 'debit';
        merchantDetermined = true;
      }
      // Mobile Banking transfer: "MB:Subscriptions"
      else if (reason.startsWith('MB:')) {
        final label = reason.substring(3).split('/').first.trim();
        merchant = label.isNotEmpty ? _toTitleCase(label) : 'Bank Transfer';
        category = 'Transfers';
        merchantDetermined = true;
      }
      // Standing Order received: "S/O FROM WELIKALA J P D"
      else if (RegExp(r'S/O FROM', caseSensitive: false).hasMatch(reason)) {
        final name = reason.replaceAll(RegExp(r'S/O FROM\s*', caseSensitive: false), '').trim();
        merchant = name.isNotEmpty ? _toTitleCase(name) : 'Standing Order';
        category = type == 'credit' ? 'Income' : 'Transfers';
        merchantDetermined = true;
      }
      // Mobile Banking Bill Payment (non-CC): "MB BillPmt/Dialog Mobile/..."
      else if (RegExp(r'^MB BillPmt', caseSensitive: false).hasMatch(reason)) {
        final parts = reason.split('/');
        if (parts.length > 1) {
          final billMerchant = parts[1].trim();
          // Only use if it's not a pure digit string (e.g. card numbers)
          if (billMerchant.isNotEmpty && !RegExp(r'^\d+$').hasMatch(billMerchant)) {
            merchant = _toTitleCase(billMerchant.split(' ').first);
          }
        }
        category = 'Bills & Utilities';
        merchantDetermined = true;
      }
      // Interest payment
      else if (reasonLower.contains('int.pd') || reasonLower.contains('interest pd')) {
        merchant = 'Bank Interest';
        category = 'Income';
        type = 'credit';
        merchantDetermined = true;
      }
    }

    // --- STEP 6: Extract merchant (if not from Reason) ---
    if (!merchantDetermined) {
      // HNB VC format: "VC : **6302 :UBER EATS 852 (Apprx)"
      final vcMatch = _hnbVcMerchantPattern.firstMatch(smsBody);
      if (vcMatch != null) {
        merchant = vcMatch.group(1)!.trim();
        debugPrint('💳 On-device: HNB VC merchant: $merchant');
      }
      // Location field for internet/international transactions
      else if (smsBody.toUpperCase().contains('LOCATION:')) {
        final locMatch = _locationPattern.firstMatch(smsBody);
        if (locMatch != null) {
          merchant = _cleanLocationMerchant(locMatch.group(1)!);
        }
      }
      // General "at MERCHANT" patterns
      else {
        merchant = _extractMerchant(smsBody);
      }
    }

    // --- STEP 7: Extract date ---
    final date = _extractDate(smsBody);
    final createdAt = _dateToDateTime(date);

    // --- STEP 8: Bank ---
    String bank = SmsValidator.getBankFromSender(sender);
    if (bank == 'Unknown Bank') bank = _extractBankFromBody(smsBody);

    // --- STEP 9: Account mask (skip if already from CC) ---
    if (!isCreditCard) {
      accountMask = _extractAccountMask(smsBody);
    }

    // --- STEP 10: Balance ---
    final balance = _extractBalance(smsBody);

    // --- STEP 11: Merchant DB + category ---
    double confidence = 0.60;
    if (!merchantDetermined && merchant != 'Unknown') {
      final matchResult = MerchantDatabase.lookup(merchant);
      if (matchResult.isFound) {
        if (matchResult.merchant != null && matchResult.merchant != 'Unknown') {
          merchant = matchResult.merchant!;
        }
        category = matchResult.category ?? _guessCategory(merchant);
        confidence = matchResult.confidence;
        debugPrint('📊 On-device: $merchant → $category (${matchResult.source}, ${(confidence * 100).toStringAsFixed(0)}%)');
      } else {
        category = _guessCategory(merchant);
        confidence = 0.50;
      }
    } else if (merchantDetermined) {
      confidence = 0.85;
      if (category == 'General') category = _guessCategory(merchant);
    }

    if (foreignCurrency != null) confidence = max(confidence, 0.80);

    final transaction = AppTransaction.create(
      userId: userId,
      bank: bank,
      bankName: bank,
      amount: amount,
      merchant: merchant,
      type: type,
      date: date,
      category: category,
      accountType: accountType,
      accountMask: accountMask,
      availableBalance: balance,
      foreignCurrency: foreignCurrency,
      foreignAmount: foreignAmount,
      source: 'sms_on_device',
      smsRawText: smsBody,
      aiConfidence: confidence,
      createdAt: createdAt,
    );

    _exactCache[cacheKey] = transaction;
    return transaction;
  }

  // ==================== AMOUNT EXTRACTION ====================

  static double _extractAmount(String sms) {
    for (var pattern in _amountPatterns) {
      final matches = pattern.allMatches(sms);
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          // Check 30-char window before the match for balance indicators
          final contextStart = max(0, match.start - 30);
          final context = sms.substring(contextStart, match.start).toLowerCase();
          if (!context.contains('bal') && !context.contains('avail')) {
            return amount;
          }
        }
      }
    }
    return 0;
  }

  // ==================== TYPE DETERMINATION ====================

  static String _determineType(String sms) {
    final lower = sms.toLowerCase();
    // Explicit credit indicators
    if (RegExp(r'credited\s+to|deposited|salary\s+credit|thank you for your payment')
        .hasMatch(lower)) { return 'credit'; }
    // Explicit debit indicators
    if (RegExp(r'debited\s+to|debited\s+from|purchase|approved\s+on\s+your\s+card')
        .hasMatch(lower)) { return 'debit'; }
    // Standalone "credited" (fallback, avoids matching "Credit Card")
    if (RegExp(r'\bcredited\b').hasMatch(lower)) { return 'credit'; }
    return 'debit';
  }

  // ==================== MERCHANT EXTRACTION ====================

  static String _extractMerchant(String sms) {
    final patterns = [
      // "at MERCHANT NAME" (credit card receipts)
      RegExp(r'\bat\s+([A-Za-z0-9][\w\s&\-\.]{1,38})(?=\s+(?:Available|on\s+\d)|\s*$)', caseSensitive: false),
      // "to MERCHANT"
      RegExp(r'\bto\s+([A-Za-z][\w\s&\-\.]{1,38})(?=\s+on\s+\d|\s*$)', caseSensitive: false),
      // "from MERCHANT"
      RegExp(r'\bfrom\s+([A-Za-z][\w\s&\-\.]{1,38})(?=\s+on\s+\d|\s*$)', caseSensitive: false),
    ];
    for (var pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        final m = match.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (m.length > 1 && !_isNotAMerchant(m)) return m;
      }
    }
    return 'Unknown';
  }

  static String _cleanLocationMerchant(String location) {
    // "ANTHROPIC* CLAUDE SUB" → "Anthropic Claude Sub"
    String cleaned = location
        .replaceAll('*', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Remove trailing 2-letter country code (", US" or " US")
    cleaned = cleaned.replaceAll(RegExp(r'\s+[A-Z]{2}\s*$'), '').trim();
    if (cleaned.length > 40) cleaned = cleaned.substring(0, 40);
    return _toTitleCase(cleaned);
  }

  static bool _isNotAMerchant(String text) {
    final lower = text.toLowerCase();
    const nonMerchants = ['lkr', 'rs', 'debited', 'credited', 'balance', 'bal',
      'avl', 'avail', 'alert', 'sms', 'call', 'hotline', 'protect', 'scams', 'otp'];
    return nonMerchants.any((w) => lower == w) || text.length < 2;
  }

  // ==================== DATE EXTRACTION ====================

  static String _extractDate(String sms) {
    for (var pattern in _datePatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        final normalised = _normalizeDate(match.group(1) ?? '');
        if (normalised != 'Today') return normalised;
      }
    }
    return 'Today';
  }

  static String _normalizeDate(String dateStr) {
    try {
      dateStr = dateStr.trim();
      const monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                          'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

      // "03-Aug-2026" or "03-Aug" or "03/AUG/2026"
      final dashMatch = RegExp(r'^(\d{1,2})[-/]([A-Za-z]{3,})(?:[-/]\d{2,4})?$').firstMatch(dateStr);
      if (dashMatch != null) {
        return '${dashMatch.group(1)!.padLeft(2, '0')}-${dashMatch.group(2)!.substring(0, 3).toUpperCase()}';
      }

      // "26.07.26" or "28/07/26" or "28/07/2026"
      final numMatch = RegExp(r'^(\d{2})[./](\d{2})[./](\d{2,4})$').firstMatch(dateStr);
      if (numMatch != null) {
        final day = int.parse(numMatch.group(1)!);
        final month = int.parse(numMatch.group(2)!);
        if (month >= 1 && month <= 12) {
          return '${day.toString().padLeft(2, '0')}-${monthNames[month - 1]}';
        }
      }
    } catch (_) {}
    return 'Today';
  }

  // ==================== DATE → DATETIME ====================

  static DateTime _dateToDateTime(String date) {
    if (date == 'Today') return DateTime.now();
    try {
      const months = {'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
                      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12};
      final parts = date.split('-');
      if (parts.length >= 2) {
        final day = int.parse(parts[0]);
        final month = months[parts[1].toUpperCase()] ?? DateTime.now().month;
        final year = DateTime.now().year;
        final txDate = DateTime(year, month, day);
        return txDate.isAfter(DateTime.now()) ? DateTime(year - 1, month, day) : txDate;
      }
    } catch (_) {}
    return DateTime.now();
  }

  // ==================== BANK EXTRACTION ====================

  static String _extractBankFromBody(String sms) {
    final lower = sms.toLowerCase();
    if (lower.contains('combank') || lower.contains('commercial bank')) return 'Commercial Bank';
    if (lower.contains('hnb')) return 'HNB';
    if (lower.contains('sampath')) return 'Sampath Bank';
    if (lower.contains('boc') || lower.contains('bank of ceylon')) return 'BOC';
    if (lower.contains('ndb') || lower.contains('nations')) return 'NDB';
    if (lower.contains('seylan')) return 'Seylan Bank';
    return 'Unknown Bank';
  }

  // ==================== ACCOUNT MASK EXTRACTION ====================

  static String _extractAccountMask(String sms) {
    // Credit card: 6+ asterisks then 4 digits → handled by _creditCardTxnPattern before here
    final cc = RegExp(r'\*{6,}(\d{4})').firstMatch(sms);
    if (cc != null) return cc.group(1)!;

    // Asterisk format: "***7603" → "7603"
    final asterisk = _asteriskMaskPattern.firstMatch(sms);
    if (asterisk != null) return asterisk.group(1)!;

    // XXXXX format: "09302XXXXX34" → "34"
    final x = _xMaskPattern.firstMatch(sms);
    if (x != null) return x.group(1)!;

    return '';
  }

  /// Returns the last 2 digits of a mask — used as the account grouping key.
  /// "7603" and "03" both return "03" so they merge into one account in the UI.
  static String maskGroupKey(String mask) {
    if (mask.length < 2) return mask;
    return mask.substring(mask.length - 2);
  }

  // ==================== BALANCE EXTRACTION ====================

  static double? _extractBalance(String sms) {
    final match = _balancePattern.firstMatch(sms);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  // ==================== CATEGORY GUESSING ====================

  static String _guessCategory(String merchant) {
    final matchResult = MerchantDatabase.lookup(merchant);
    if (matchResult.isFound && matchResult.category != null) {
      return matchResult.category!;
    }
    final lower = merchant.toLowerCase();
    if (RegExp(r'keells|cargills|food city|arpico|glomark|supermarket|spar|sathosa').hasMatch(lower)) return 'Groceries';
    if (RegExp(r'uber\s+eats|ubereats').hasMatch(lower)) return 'Dining';
    if (RegExp(r'\buber\b|pickme|pick me|kangaroo|bus|taxi|tuk|parking|fuel|petrol|ioc|ceypetco').hasMatch(lower)) return 'Transport';
    if (RegExp(r'restaurant|hotel|cafe|bakery|pizza|kfc|mcdonalds|food|dining|barista|eat').hasMatch(lower)) return 'Dining';
    if (RegExp(r'dialog|mobitel|hutch|slt|ceb|water|lankapay|electricity|bill|utility').hasMatch(lower)) return 'Bills & Utilities';
    if (RegExp(r'netflix|spotify|amazon|prime|youtube|apple|google|subscription|zoom|canva|adobe|microsoft|anthropic|claude').hasMatch(lower)) return 'Recurring Payments';
    if (RegExp(r'shop|mart|store|odell|fashion|mall|clothing|daraz|cool planet').hasMatch(lower)) return 'Shopping';
    if (RegExp(r'transfer|remittance|credit card payment|bank transfer').hasMatch(lower)) return 'Transfers';
    if (RegExp(r'salary|wage|payroll|income|interest|standing order').hasMatch(lower)) return 'Income';
    return 'General';
  }

  // ==================== HELPERS ====================

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      // Preserve all-caps acronyms: ATM, KFC, SLT, CEB, HNB, BOC, etc.
      if (word.length > 1 && word == word.toUpperCase()) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static int get cacheSize => _exactCache.length;
  static void clearCache() => _exactCache.clear();
}
