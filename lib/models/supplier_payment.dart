class SupplierPayment {
  final String id;
  final DateTime date;
  final String supplierId;
  final double amountPaid;

  SupplierPayment({
    required this.id,
    required this.date,
    required this.supplierId,
    required this.amountPaid,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'supplier_id': supplierId,
        'amount_paid': amountPaid,
      };

  factory SupplierPayment.fromMap(Map<String, dynamic> map) => SupplierPayment(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        supplierId: map['supplier_id'] as String,
        amountPaid: (map['amount_paid'] as num).toDouble(),
      );
}
