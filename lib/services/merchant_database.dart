// File: lib/services/merchant_database.dart

class MerchantEntry {
  final String canonicalName;
  final String category;
  final List<String> aliases;
  final List<String> keywords;

  const MerchantEntry({
    required this.canonicalName,
    required this.category,
    this.aliases = const [],
    this.keywords = const [],
  });
}

class MerchantDatabase {
  // ==================== SRI LANKAN MERCHANT DATABASE ====================
  
  static final Map<String, MerchantEntry> _database = {};
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _addAll(_groceryMerchants());
    _addAll(_transportMerchants());
    _addAll(_diningMerchants());
    _addAll(_utilitiesMerchants());
    _addAll(_shoppingMerchants());
    _addAll(_subscriptionMerchants());
    _addAll(_bankingMerchants());
    _addAll(_healthMerchants());
    _addAll(_educationMerchants());
    _addAll(_otherMerchants());
    _initialized = true;
  }

  static void _addAll(List<MerchantEntry> entries) {
    for (var entry in entries) {
      _database[entry.canonicalName.toLowerCase()] = entry;
      for (var alias in entry.aliases) {
        _database[alias.toLowerCase()] = entry;
      }
    }
  }

  // ==================== GROCERIES ====================
  
  static List<MerchantEntry> _groceryMerchants() => [
    const MerchantEntry(canonicalName: 'Keells', category: 'Groceries', aliases: [
      'keells super', 'keells supermarket', 'kls', 'kls super', 'kells',
      'keells kollupitiya', 'keells wattala', 'keells negombo',
      'keells rajagiriya', 'keells nugegoda', 'keells mount lavinia',
    ], keywords: ['keells', 'kls', 'kells']),
    const MerchantEntry(canonicalName: 'Cargills', category: 'Groceries', aliases: [
      'cargills food city', 'cargills foodcity', 'cargills express',
      'cargils', 'cargills wattala', 'cargills kollupitiya',
    ], keywords: ['cargills', 'cargils', 'food city', 'foodcity']),
    const MerchantEntry(canonicalName: 'Arpico', category: 'Groceries', aliases: [
      'arpico superstore', 'arpico supermarket', 'arpico hyde park',
    ], keywords: ['arpico']),
    const MerchantEntry(canonicalName: 'Glomark', category: 'Groceries', aliases: [
      'glomark supermarket', 'glomark express',
    ], keywords: ['glomark']),
    const MerchantEntry(canonicalName: 'SPAR', category: 'Groceries', aliases: [
      'spar supermarket', 'spar kalubowila', 'spar wattala',
    ], keywords: ['spar']),
    const MerchantEntry(canonicalName: 'Laughs', category: 'Groceries', aliases: [
      'laughs supermarket', 'laughs super',
    ], keywords: ['laughs']),
    const MerchantEntry(canonicalName: 'Sathosa', category: 'Groceries', aliases: [
      'lanka sathosa', 'sathosa outlet',
    ], keywords: ['sathosa']),
    const MerchantEntry(canonicalName: 'Supermarket', category: 'Groceries', aliases: [], keywords: [
      'supermarket', 'super market', 'grocery', 'groceries',
    ]),
  ];

  // ==================== TRANSPORT ====================
  
  static List<MerchantEntry> _transportMerchants() => [
    const MerchantEntry(canonicalName: 'PickMe', category: 'Transport', aliases: [
      'pickme', 'pick me', 'pickme foods', 'pickme flash',
    ], keywords: ['pickme', 'pick me']),
    const MerchantEntry(canonicalName: 'Uber', category: 'Transport', aliases: [
      'uber sri lanka', 'uber sl',
    ], keywords: ['uber']),
    const MerchantEntry(canonicalName: 'Kangaroo', category: 'Transport', aliases: [
      'kangaroo cabs', 'kangaroo taxi',
    ], keywords: ['kangaroo']),
    const MerchantEntry(canonicalName: 'Fuel Station', category: 'Transport', aliases: [
      'fuel', 'petrol', 'diesel', 'ioc', 'lanka ioc', 'ceypetco',
      'filling station', 'petrol shed',
    ], keywords: ['fuel', 'petrol', 'diesel', 'ioc', 'ceypetco']),
    const MerchantEntry(canonicalName: 'Parking', category: 'Transport', aliases: [], keywords: ['parking']),
    const MerchantEntry(canonicalName: 'Highway Toll', category: 'Transport', aliases: [
      'expressway', 'highway', 'toll',
    ], keywords: ['expressway', 'highway', 'toll']),
  ];

  // ==================== DINING ====================
  
  static List<MerchantEntry> _diningMerchants() => [
    const MerchantEntry(canonicalName: 'Pizza Hut', category: 'Dining', aliases: [
      'pizza hut lanka', 'pizzahut',
    ], keywords: ['pizza hut', 'pizzahut']),
    const MerchantEntry(canonicalName: 'KFC', category: 'Dining', aliases: [], keywords: ['kfc']),
    const MerchantEntry(canonicalName: 'McDonalds', category: 'Dining', aliases: [
      'mcdonalds', 'mc donalds', 'mcd',
    ], keywords: ['mcdonalds', 'mcdonald', 'mcd']),
    const MerchantEntry(canonicalName: 'Barista', category: 'Dining', aliases: [], keywords: ['barista']),
    const MerchantEntry(canonicalName: 'Uber Eats', category: 'Dining', aliases: [
      'ubereats', 'UBER EATS', 'uber eats sri lanka',
    ], keywords: ['uber eats', 'ubereats']),
    const MerchantEntry(canonicalName: 'PickMe Food', category: 'Dining', aliases: [
      'pickme food', 'pickmefoods',
    ], keywords: ['pickme food', 'pickmefoods']),
    const MerchantEntry(canonicalName: 'Restaurant', category: 'Dining', aliases: [], keywords: [
      'restaurant', 'hotel', 'cafe', 'bake', 'bakery', 'food', 'dining',
      'kitchen', 'eat', 'dine', 'coffee', 'tea',
    ]),
  ];

  // ==================== UTILITIES ====================
  
  static List<MerchantEntry> _utilitiesMerchants() => [
    const MerchantEntry(canonicalName: 'Dialog', category: 'Bills & Utilities', aliases: [
      'dialog axiata', 'dialog gsm', 'dialog tv', 'dialog postpaid',
      'dialog prepaid', 'dialog broadband',
    ], keywords: ['dialog']),
    const MerchantEntry(canonicalName: 'Mobitel', category: 'Bills & Utilities', aliases: [
      'mobitel pvt', 'mobitel postpaid', 'mobitel prepaid',
    ], keywords: ['mobitel']),
    const MerchantEntry(canonicalName: 'Hutch', category: 'Bills & Utilities', aliases: [
      'hutchison', 'hutch telecom',
    ], keywords: ['hutch']),
    const MerchantEntry(canonicalName: 'SLT', category: 'Bills & Utilities', aliases: [
      'slt fibre', 'slt broadband', 'sri lanka telecom', 'slt mobitel',
    ], keywords: ['slt', 'sri lanka telecom']),
    const MerchantEntry(canonicalName: 'CEB', category: 'Bills & Utilities', aliases: [
      'ceylon electricity board', 'electricity bill', 'ceb bill',
    ], keywords: ['ceb', 'electricity', 'electric']),
    const MerchantEntry(canonicalName: 'Water Board', category: 'Bills & Utilities', aliases: [
      'nwsdb', 'water supply', 'water bill', 'national water',
    ], keywords: ['water', 'nwsdb']),
    const MerchantEntry(canonicalName: 'LankaPay', category: 'Bills & Utilities', aliases: [
      'lankapay', 'lanka pay',
    ], keywords: ['lankapay']),
    const MerchantEntry(canonicalName: 'Dialog Bill Payment', category: 'Bills & Utilities', aliases: [
  'dialog mobile', 'dialog bill', 'dialog billpmt', 'dialog payment',
  'billpmt/dialog', 'mb billpmt',
], keywords: ['dialog', 'billpmt', 'mb billpmt']),
  ];

  // ==================== SHOPPING ====================
  
  static List<MerchantEntry> _shoppingMerchants() => [
    const MerchantEntry(canonicalName: 'ODEL', category: 'Shopping', aliases: [
      'odel', 'odel lanka',
    ], keywords: ['odel']),
    const MerchantEntry(canonicalName: 'House of Fashion', category: 'Shopping', aliases: [
      'hof', 'house of fashion',
    ], keywords: ['house of fashion', 'hof']),
    const MerchantEntry(canonicalName: 'Cool Planet', category: 'Shopping', aliases: [], keywords: ['cool planet']),
    const MerchantEntry(canonicalName: 'Daraz', category: 'Shopping', aliases: [
      'daraz.lk', 'daraz sri lanka',
    ], keywords: ['daraz']),
    const MerchantEntry(canonicalName: 'Fashion', category: 'Shopping', aliases: [], keywords: [
      'fashion', 'clothing', 'garment', 'shop', 'store', 'mall',
    ]),
  ];

  // ==================== SUBSCRIPTIONS ====================
  
  static List<MerchantEntry> _subscriptionMerchants() => [
    const MerchantEntry(canonicalName: 'Netflix', category: 'Recurring Payments', aliases: [], keywords: ['netflix']),
    const MerchantEntry(canonicalName: 'Spotify', category: 'Recurring Payments', aliases: [], keywords: ['spotify']),
    const MerchantEntry(canonicalName: 'Amazon Prime', category: 'Recurring Payments', aliases: [
      'amazon', 'prime video',
    ], keywords: ['amazon prime', 'prime video']),
    const MerchantEntry(canonicalName: 'YouTube', category: 'Recurring Payments', aliases: [
      'youtube premium', 'youtube music',
    ], keywords: ['youtube']),
    const MerchantEntry(canonicalName: 'Apple', category: 'Recurring Payments', aliases: [
      'apple music', 'apple tv', 'apple.com', 'icloud',
    ], keywords: ['apple', 'icloud']),
    const MerchantEntry(canonicalName: 'Google', category: 'Recurring Payments', aliases: [
      'google one', 'google drive', 'google play',
    ], keywords: ['google']),
    const MerchantEntry(canonicalName: 'Dialog TV', category: 'Recurring Payments', aliases: [], keywords: ['dialog tv']),
    const MerchantEntry(canonicalName: 'PEO TV', category: 'Recurring Payments', aliases: [], keywords: ['peo tv']),
    const MerchantEntry(canonicalName: 'Zoom', category: 'Recurring Payments', aliases: [
      'zoom pro', 'zoom.us',
    ], keywords: ['zoom']),
    const MerchantEntry(canonicalName: 'Canva', category: 'Recurring Payments', aliases: [
      'canva pro', 'canva.com',
    ], keywords: ['canva']),
    const MerchantEntry(canonicalName: 'Microsoft', category: 'Recurring Payments', aliases: [
      'microsoft 365', 'office 365', 'onedrive',
    ], keywords: ['microsoft', 'office 365']),
    const MerchantEntry(canonicalName: 'Adobe', category: 'Recurring Payments', aliases: [
      'adobe creative', 'adobe cloud',
    ], keywords: ['adobe']),
    const MerchantEntry(canonicalName: 'Subscription', category: 'Recurring Payments', aliases: [], keywords: [
      'subscription', 'recurring', 'monthly', 'annual',
    ]),
  ];

  // ==================== BANKING ====================
  
  static List<MerchantEntry> _bankingMerchants() => [
    const MerchantEntry(canonicalName: 'ATM Withdrawal', category: 'Transfers', aliases: [
      'atm', 'cash withdrawal', 'atm withdrawal',
    ], keywords: ['atm', 'cash withdrawal']),
    const MerchantEntry(canonicalName: 'Bank Transfer', category: 'Transfers', aliases: [
      'transfer', 'fund transfer', 'money transfer', 'remittance',
    ], keywords: ['transfer', 'remittance']),
    const MerchantEntry(canonicalName: 'Salary', category: 'Income', aliases: [
      'salary', 'wages', 'payroll',
    ], keywords: ['salary', 'wages', 'payroll']),
    const MerchantEntry(canonicalName: 'Credit Card Payment', category: 'Transfers', aliases: [
      'credit card pmt', 'cc payment', 'card payment', 'credit card settlement',
    ], keywords: ['credit card payment', 'credit card pmt']),
    const MerchantEntry(canonicalName: 'Bank Interest', category: 'Income', aliases: [
      'interest payment', 'int pd', 'interest income',
    ], keywords: ['bank interest', 'int.pd']),
    const MerchantEntry(canonicalName: 'Standing Order', category: 'Transfers', aliases: [
      's/o', 'standing order', 'so payment',
    ], keywords: ['standing order', 's/o from']),
  ];

  // ==================== HEALTH ====================
  
  static List<MerchantEntry> _healthMerchants() => [
    const MerchantEntry(canonicalName: 'Pharmacy', category: 'General', aliases: [
      'pharmacy', 'medical', 'hospital', 'clinic', 'doctor', 'channeling',
      'chemist', 'drug', 'health', 'rajya osusala',
    ], keywords: ['pharmacy', 'medical', 'hospital', 'clinic', 'doctor']),
  ];

  // ==================== EDUCATION ====================
  
  static List<MerchantEntry> _educationMerchants() => [
    const MerchantEntry(canonicalName: 'Education', category: 'General', aliases: [
      'school', 'college', 'university', 'tuition', 'class', 'course',
      'exam', 'book', 'stationary',
    ], keywords: ['school', 'college', 'university', 'tuition', 'exam']),
  ];

  // ==================== OTHER ====================
  
  static List<MerchantEntry> _otherMerchants() => [
    const MerchantEntry(canonicalName: 'Insurance', category: 'General', aliases: [
      'insurance', 'life insurance', 'ceylinco', 'aia', 'softlogic',
    ], keywords: ['insurance']),
    const MerchantEntry(canonicalName: 'Government', category: 'General', aliases: [
      'government', 'gov', 'department', 'municipal',
    ], keywords: ['government', 'gov']),
  ];

  // ==================== LOOKUP ====================

  static MerchantMatchResult lookup(String rawMerchant) {
    initialize();
    
    if (rawMerchant.isEmpty) {
      return MerchantMatchResult.notFound();
    }

    String cleaned = rawMerchant.toLowerCase().trim();
    
    // Remove common suffixes that don't help matching
    cleaned = cleaned
        .replaceAll(RegExp(r'\b(pvt|ltd|pvt ltd|private limited|company)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Step 1: Exact match
    if (_database.containsKey(cleaned)) {
      final entry = _database[cleaned]!;
      return MerchantMatchResult(
        merchant: entry.canonicalName,
        category: entry.category,
        confidence: 1.0,
        source: 'exact_match',
      );
    }

    // Step 2: Alias match (check if any alias is contained in the cleaned text)
    for (var entry in _database.values) {
      for (var alias in entry.aliases) {
        if (cleaned.contains(alias.toLowerCase())) {
          return MerchantMatchResult(
            merchant: entry.canonicalName,
            category: entry.category,
            confidence: 0.95,
            source: 'alias_match',
          );
        }
      }
    }

    // Step 3: Keyword match
    double bestKeywordScore = 0;
    MerchantEntry? bestKeywordMatch;
    
    for (var entry in _database.values) {
      for (var keyword in entry.keywords) {
        if (cleaned.contains(keyword.toLowerCase())) {
          double score = keyword.length / cleaned.length;
          if (score > bestKeywordScore) {
            bestKeywordScore = score;
            bestKeywordMatch = entry;
          }
        }
      }
    }
    
    if (bestKeywordMatch != null && bestKeywordScore > 0.3) {
      return MerchantMatchResult(
        merchant: bestKeywordMatch.canonicalName,
        category: bestKeywordMatch.category,
        confidence: 0.70 + (bestKeywordScore * 0.2),
        source: 'keyword_match',
      );
    }

    // Step 4: Fuzzy match using Levenshtein distance
    return _fuzzyMatch(cleaned);
  }

  static MerchantMatchResult _fuzzyMatch(String cleaned) {
    String? bestMatch;
    double bestScore = 0;

    for (var key in _database.keys) {
      int distance = _levenshteinDistance(cleaned, key);
      double score = 1.0 - (distance / key.length.clamp(1, 999));

      if (score > bestScore && score > 0.65) {
        bestScore = score;
        bestMatch = key;
      }
    }

    if (bestMatch != null) {
      final entry = _database[bestMatch]!;
      return MerchantMatchResult(
        merchant: entry.canonicalName,
        category: entry.category,
        confidence: bestScore.clamp(0.0, 0.85),
        source: 'fuzzy_match',
      );
    }

    return MerchantMatchResult.notFound();
  }

  /// Levenshtein distance for fuzzy string matching
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> prev = List.generate(s2.length + 1, (i) => i);
    List<int> curr = List.filled(s2.length + 1, 0);

    for (int i = 1; i <= s1.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = [curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[s2.length];
  }

  /// Get database size for analytics
  static int get size => _database.length;
}

// ==================== MATCH RESULT ====================

class MerchantMatchResult {
  final String? merchant;
  final String? category;
  final double confidence;
  final String source; // 'exact_match', 'alias_match', 'keyword_match', 'fuzzy_match', 'not_found'

  const MerchantMatchResult({
    this.merchant,
    this.category,
    required this.confidence,
    required this.source,
  });

  factory MerchantMatchResult.notFound() => const MerchantMatchResult(
    merchant: null,
    category: null,
    confidence: 0,
    source: 'not_found',
  );

  bool get isFound => confidence > 0;
  bool get isHighConfidence => confidence >= 0.85;
  bool get isMediumConfidence => confidence >= 0.60 && confidence < 0.85;
  bool get isLowConfidence => confidence > 0 && confidence < 0.60;
}