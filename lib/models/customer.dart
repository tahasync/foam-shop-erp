class Customer {
  final String id;
  final String name;
  final String phone;
  final bool isArchived;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'is_archived': isArchived,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        isArchived: map['is_archived'] as bool? ?? false,
      );

  Customer copyWith({String? id, String? name, String? phone, bool? isArchived}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        isArchived: isArchived ?? this.isArchived,
      );
}
