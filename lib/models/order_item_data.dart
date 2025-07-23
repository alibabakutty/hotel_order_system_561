class OrderItem {
  final String itemCode;
  final String itemName;
  final double quantity;
  final double itemRateAmount;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.itemRateAmount,
  });

  // Add this empty constructor
  factory OrderItem.empty() =>
      OrderItem(itemCode: '', itemName: '', quantity: 1.0, itemRateAmount: 0.0);

  Map<String, dynamic> toMap() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'itemRateAmount': itemRateAmount,
    };
  }

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      itemRateAmount: map['itemRateAmount']?.toDouble() ?? 0.0,
    );
  }
}
