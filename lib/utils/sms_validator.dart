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
      'hnb', 'seylan', 'ntb', 'ndb', 'peoples'
    ];
    bool isBankSender = allowedBankSenders.any((bank) => lowerSender.contains(bank));

    // 2. Check for transaction-specific keywords
    final transactionKeywords = ['debited', 'credited', 'payment', 'transfer', 'lkr', 'rs'];
    bool hasTransactionKeyword = transactionKeywords.any((keyword) => lowerBody.contains(keyword));

    // 3. Filter out promotional messages to save Gemini quota
    final promoKeywords = ['offer', 'promo', 'discount', '% off', 'sale'];
    bool hasPromoKeyword = promoKeywords.any((keyword) => lowerBody.contains(keyword));

    return isBankSender && hasTransactionKeyword && !hasPromoKeyword;
  }

  /// Layer 2: The Gemini Failsafe Instruction
  /// This strict system instruction guarantees we get standard JSON and filters out false positives.
  static const String geminiSystemInstruction = '''
  You are an extraction tool for Sri Lankan bank transaction SMS alerts.
  Extract the following details and return ONLY a valid JSON object with these exact keys:
  - "amount" (numeric value)
  - "merchant" (string)
  - "category" (logical spending category, e.g., "Groceries", "Utilities")
  - "type" ("debit" or "credit")
  
  CRITICAL: If the message is NOT a bank transaction (e.g., promotional, OTP, or informational),
  return EXACTLY this JSON and nothing else: {"error": "Not a valid transaction SMS"}
  ''';
}