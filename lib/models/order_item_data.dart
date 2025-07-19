class OrderItem {
  final String itemCode;
  final String itemName;
  final double itemAmount;
  final bool itemStatus;
  final double quantity;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.itemAmount,
    required this.itemStatus,
    required this.quantity,
  });

  // Add this empty constructor
  factory OrderItem.empty() => OrderItem(
    itemCode: '',
    itemName: '',
    itemAmount: 0.0,
    itemStatus: true,
    quantity: 1.0,
  );

  Map<String, dynamic> toMap() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'itemAmount': itemAmount,
      'itemStatus': itemStatus,
      'quantity': quantity,
    };
  }

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      itemAmount: map['itemAmount']?.toDouble() ?? 0.0,
      itemStatus: map['itemStatus'] ?? true,
      quantity: map['quantity']?.toDouble() ?? 0.0,
    );
  }
}
