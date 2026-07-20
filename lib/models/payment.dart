class Payment {
  final String id;
  final DateTime date;
  final String customerId;
  final double amountCollected;

  Payment({
    required this.id,
    required this.date,
    required this.customerId,
    required this.amountCollected,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'customer_id': customerId,
        'amount_collected': amountCollected,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        customerId: map['customer_id'] as String,
        amountCollected: (map['amount_collected'] as num).toDouble(),
      );
}
