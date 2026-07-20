class Product {
  final String id;
  final String name;
  final String type;
  final double sizeLength;
  final double sizeWidth;
  final double thickness;
  final double density;
  final String unitType;
  final double unitPrice;
  final double costPrice;
  final double currentStock;
  final double lowStockThreshold;
  final bool isArchived;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeLength,
    required this.sizeWidth,
    required this.thickness,
    required this.density,
    required this.unitType,
    required this.unitPrice,
    this.costPrice = 0,
    required this.currentStock,
    required this.lowStockThreshold,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'size_length': sizeLength,
        'size_width': sizeWidth,
        'thickness': thickness,
        'density': density,
        'unit_type': unitType,
        'unit_price': unitPrice,
        'cost_price': costPrice,
        'current_stock': currentStock,
        'low_stock_threshold': lowStockThreshold,
        'is_archived': isArchived,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        sizeLength: (map['size_length'] as num).toDouble(),
        sizeWidth: (map['size_width'] as num).toDouble(),
        thickness: (map['thickness'] as num).toDouble(),
        density: (map['density'] as num).toDouble(),
        unitType: map['unit_type'] as String,
        unitPrice: (map['unit_price'] as num).toDouble(),
        costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
        currentStock: (map['current_stock'] as num).toDouble(),
        lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
        isArchived: map['is_archived'] as bool? ?? false,
      );

  Product copyWith({
    String? id, String? name, String? type,
    double? sizeLength, double? sizeWidth, double? thickness, double? density,
    String? unitType, double? unitPrice, double? costPrice,
    double? currentStock, double? lowStockThreshold, bool? isArchived,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        sizeLength: sizeLength ?? this.sizeLength,
        sizeWidth: sizeWidth ?? this.sizeWidth,
        thickness: thickness ?? this.thickness,
        density: density ?? this.density,
        unitType: unitType ?? this.unitType,
        unitPrice: unitPrice ?? this.unitPrice,
        costPrice: costPrice ?? this.costPrice,
        currentStock: currentStock ?? this.currentStock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        isArchived: isArchived ?? this.isArchived,
      );

  bool get isLowStock => currentStock <= lowStockThreshold;

  String get stockLabel {
    if (unitType == 'per_sqft') return '${currentStock.toStringAsFixed(1)} sq.ft';
    return currentStock.toStringAsFixed(0);
  }
}
