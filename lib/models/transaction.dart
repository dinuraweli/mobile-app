class AppTransaction {
  final String id;
  final String bank;
  final String bankName;
  final double amount;
  final String merchant;
  final String type;
  final String date;
  final String category;
  final String accountType;
  final String accountMask;
  final double? availableBalance;

  AppTransaction({
    String? id,
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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
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
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'],
        bank: json['bank'],
        bankName: json['bankName'] ?? '',
        amount: json['amount'],
        merchant: json['merchant'],
        type: json['type'],
        date: json['date'],
        category: json['category'],
        accountType: json['accountType'] ?? 'Unknown',
        accountMask: json['accountMask'] ?? '',
        availableBalance: json['availableBalance'] != null ? double.tryParse(json['availableBalance'].toString()) : null,
      );
}
