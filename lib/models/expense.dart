class Expense {
  final String id;
  final DateTime date;
  final String category;
  final String description;
  final double amount;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    this.description = '',
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'amount': amount,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        category: map['category'] as String,
        description: map['description'] as String? ?? '',
        amount: (map['amount'] as num).toDouble(),
      );
}
