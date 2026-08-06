// File: lib/utils/sms_validator.dart

class SmsValidator {
  /// Layer 1: The Gateway Filter
  /// Checks if the SMS is likely a bank transaction before hitting the Gemini API
  static bool isBankTransaction(String? sender, String? body) {
    if (sender == null || body == null) return false;

    final lowerSender = sender.toLowerCase();
    final lowerBody = body.toLowerCase();

    // 1. Check if the sender is a known Sri Lankan bank
    final allowedBankSenders = [
      'commercial', 'combank', 'boc', 'sampath', 
      'hnb', 'seylan', 'ntb', 'ndb', 'peoples',
      'hsbc', 'dfcc', 'pan asia', 'union',
      'nations', 'card', 'cards', 'visa', 'master',
    ];
    bool isBankSender = allowedBankSenders.any((bank) => lowerSender.contains(bank));

    // 2. Check for transaction-specific keywords
    final transactionKeywords = ['debited', 'credited', 'payment', 'transfer', 'lkr', 'rs', 'purchase', 'withdrawal', 'deposit', 'transaction approved', 'transaction'];
    bool hasTransactionKeyword = transactionKeywords.any((keyword) => lowerBody.contains(keyword));

    // 3. Filter out promotional messages to save Gemini quota
    final promoKeywords = ['offer', 'promo', 'discount', '% off', 'sale', 'apply now', 'limited time'];
    bool hasPromoKeyword = promoKeywords.any((keyword) => lowerBody.contains(keyword));

    return isBankSender && hasTransactionKeyword && !hasPromoKeyword;
  }

  /// Map sender ID to bank name
  static String getBankFromSender(String? sender) {
    if (sender == null) return 'Unknown Bank';
    
    final lower = sender.toLowerCase().trim();
    
    // Direct matches
    if (lower.contains('combank') || lower.contains('commercial')) return 'Commercial Bank';
    if (lower.contains('hnb')) return 'HNB';
    if (lower.contains('sampath')) return 'Sampath Bank';
    if (lower.contains('boc') || lower.contains('bank of ceylon')) return 'BOC';
    if (lower.contains('ndb')) return 'NDB';
    if (lower.contains('seylan')) return 'Seylan Bank';
    if (lower.contains('ntb') || lower.contains('nations trust')) return 'Nations Trust Bank';
    if (lower.contains('nations') || lower.contains('nations trust')) return 'Nations Trust Bank';
    if (lower.contains('hsbc')) return 'HSBC';
    if (lower.contains('dfcc')) return 'DFCC Bank';
    if (lower.contains('peoples') || lower.contains('people\'s')) return 'Peoples Bank';
    if (lower.contains('pan asia')) return 'Pan Asia Bank';
    if (lower.contains('union')) return 'Union Bank';
    if (lower.contains('card') || lower.contains('visa') || lower.contains('master')) {
  // Try to identify bank from the message body later
  return 'Card Transaction';
}
    return 'Unknown Bank';
  }

  /// Layer 2: The Gemini Failsafe Instruction
  static const String geminiSystemInstruction = '''
You are an extraction tool for Sri Lankan bank transaction SMS alerts.
Extract the following details and return ONLY a valid JSON object.

CRITICAL RULES:
1. The "category" field MUST be chosen exactly from this list:
   ["Groceries", "Transport", "Dining", "Bills & Utilities", "Recurring Payments", "Shopping", "Transfers", "Income", "General"].
2. "bankName": Extract the name of the bank from the SMS content. If not mentioned, use "Unknown Bank".
3. "availableBalance": Extract the remaining account balance if mentioned in the SMS (return as a numeric value). If not mentioned, return null.
4. "date": Extract the transaction date from the SMS in DD-MMM format (e.g., "24-MAY"). If no date found, use "Today".
5. "merchant": The vendor/payee name where the transaction occurred.

The keys must exactly match: 
- "amount" (numeric)
- "merchant" (string)
- "category" (from the list above)
- "type" ("debit" or "credit")
- "bankName" (string)
- "availableBalance" (numeric or null)
- "date" (string, DD-MMM format)
- "account_mask" (string, last 4 digits)

CRITICAL FAILSAFE: If the message is NOT a bank transaction,
return EXACTLY this JSON: {"error": "Not a valid transaction SMS"}
''';
}