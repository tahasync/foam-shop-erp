class Supplier {
  final String id;
  final String name;
  final String phone;
  final bool isArchived;

  Supplier({
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

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        isArchived: map['is_archived'] as bool? ?? false,
      );

  Supplier copyWith({String? id, String? name, String? phone, bool? isArchived}) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        isArchived: isArchived ?? this.isArchived,
      );
}
