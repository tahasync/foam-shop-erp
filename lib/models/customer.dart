class Customer {
  final String id;
  final String name;
  final String phone;
  final double baqaya;
  final bool isArchived;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.baqaya = 0,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'baqaya': baqaya,
        'is_archived': isArchived,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?)?.trim().isEmpty == true ? 'Unnamed Customer' : (map['name'] as String?) ?? 'Unnamed Customer',
        phone: map['phone'] as String? ?? '',
        baqaya: (map['baqaya'] as num?)?.toDouble() ?? 0,
        isArchived: map['is_archived'] as bool? ?? false,
      );

  Customer copyWith({String? id, String? name, String? phone, double? baqaya, bool? isArchived}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        baqaya: baqaya ?? this.baqaya,
        isArchived: isArchived ?? this.isArchived,
      );
}
