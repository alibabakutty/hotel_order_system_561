class OrderItem {
  String itemCode;
  String itemName;
  double itemAmount;
  bool itemStatus;
  int quantity;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.itemAmount,
    required this.itemStatus,
    required this.quantity,
  });

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
      quantity: map['quantity'] ?? 1,
    );
  }
}
