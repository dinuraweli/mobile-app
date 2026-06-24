class AppTransaction {
  final String id;
  final String bank;
  final double amount;
  final String merchant;
  final String type;
  final String date;
  final String category;
  final String accountType;
  final String accountMask;

  AppTransaction({
    String? id,
    required this.bank,
    required this.amount,
    required this.merchant,
    required this.type,
    required this.date,
    required this.category,
    this.accountType = 'Unknown',
    this.accountMask = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank': bank,
        'amount': amount,
        'merchant': merchant,
        'type': type,
        'date': date,
        'category': category,
        'accountType': accountType,
        'accountMask': accountMask,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'],
        bank: json['bank'],
        amount: json['amount'],
        merchant: json['merchant'],
        type: json['type'],
        date: json['date'],
        category: json['category'],
        accountType: json['accountType'] ?? 'Unknown',
        accountMask: json['accountMask'] ?? '',
      );
}
