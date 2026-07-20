class OpeningBalance {
  final String id;
  final DateTime date;
  final double capitalAmount;

  OpeningBalance({
    required this.id,
    required this.date,
    required this.capitalAmount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'capital_amount': capitalAmount,
      };

  factory OpeningBalance.fromMap(Map<String, dynamic> map) => OpeningBalance(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        capitalAmount: (map['capital_amount'] as num).toDouble(),
      );
}
