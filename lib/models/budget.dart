import 'package:isar/isar.dart';

part 'budget.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;

  late int userId;
  late String category;
  late double amount;
  late DateTime updatedAt;

  Budget({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.category,
    required this.amount,
  }) : updatedAt = DateTime.now();
}
