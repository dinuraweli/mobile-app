// File: lib/models/transaction.dart
import 'package:isar/isar.dart';

part 'transaction.g.dart';

@collection
class AppTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String transactionId;

  late int userId;
  late String bank;
  late String bankName;
  late double amount;
  late String merchant;
  late String type;
  late String date;
  late String category;
  late String accountType;
  late String accountMask;
  double? availableBalance;

  @Index()
  late DateTime createdAt;

  late String source;
  String? smsRawText;
  bool isSynced = false;
  double? aiConfidence;

  @ignore
  bool get isDebit => type.toLowerCase() == 'debit';

  @ignore
  bool get isCredit => type.toLowerCase() == 'credit';

  @ignore
  String get bankDisplay {
    // Clean bank name
    String cleanBank = bank
        .replaceAll('Bank', '')
        .replaceAll('bank', '')
        .trim();

    // Format account mask
    if (accountMask.isNotEmpty) {
      return '$cleanBank $accountMask';
    }
    return cleanBank;
  }

  @ignore
  String get bankShortName {
    // Map long bank names to short codes
    final lower = bank.toLowerCase();
    if (lower.contains('commercial') || lower.contains('combank')) return 'ComBank';
    if (lower.contains('sampath')) return 'Sampath';
    if (lower.contains('hnb')) return 'HNB';
    if (lower.contains('boc')) return 'BOC';
    if (lower.contains('ndb')) return 'NDB';
    if (lower.contains('seylan')) return 'Seylan';
    if (lower.contains('ntb')) return 'NTB';
    if (lower.contains('hsbc')) return 'HSBC';
    if (lower.contains('cash') || lower.contains('other')) return 'Cash';
    return bank.length > 10 ? '${bank.substring(0, 10)}...' : bank;
  }

  // Main constructor
  AppTransaction({
    this.id = Isar.autoIncrement,
    required this.transactionId,
    required this.userId,
    required this.bank,
    this.bankName = '',
    required this.amount,
    required this.merchant,
    required this.type,
    required this.date,
    required this.category,
    this.accountType = 'Unknown',
    this.accountMask = '',
    this.availableBalance,
    required this.createdAt,
    this.source = 'manual',
    this.smsRawText,
    this.isSynced = false,
    this.aiConfidence,
  });

  // Convenience factory - use this everywhere in your app!
  factory AppTransaction.create({
    required int userId,
    required String bank,
    String bankName = '',
    required double amount,
    required String merchant,
    required String type,
    String date = 'Today',
    required String category,
    String accountType = 'Unknown',
    String accountMask = '',
    double? availableBalance,
    String source = 'manual',
    String? smsRawText,
    double? aiConfidence,
  }) {
    return AppTransaction(
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      bank: bank,
      bankName: bankName.isEmpty ? bank : bankName,
      amount: amount,
      merchant: merchant,
      type: type,
      date: date,
      category: category,
      accountType: accountType,
      accountMask: accountMask,
      availableBalance: availableBalance,
      createdAt: DateTime.now(),
      source: source,
      smsRawText: smsRawText,
      aiConfidence: aiConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': transactionId,
        'userId': userId,
        'bank': bank,
        'bankName': bankName,
        'amount': amount,
        'merchant': merchant,
        'type': type,
        'date': date,
        'category': category,
        'accountType': accountType,
        'accountMask': accountMask,
        'availableBalance': availableBalance,
        'source': source,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction.create(
        userId: json['userId'] ?? 0,
        bank: json['bank']?.toString() ?? 'Unknown',
        bankName: json['bankName']?.toString() ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        merchant: json['merchant']?.toString() ?? 'Unknown',
        type: json['type']?.toString() ?? 'debit',
        date: json['date']?.toString() ?? 'Today',
        category: json['category']?.toString() ?? 'General',
        accountType: json['accountType']?.toString() ?? 'Unknown',
        accountMask: json['accountMask']?.toString() ?? '',
        availableBalance: json['availableBalance'] != null
            ? double.tryParse(json['availableBalance'].toString())
            : null,
        source: json['source']?.toString() ?? 'manual',
      );
}