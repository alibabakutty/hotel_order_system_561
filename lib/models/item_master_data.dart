import 'package:cloud_firestore/cloud_firestore.dart';

class ItemMasterData {
  final int itemCode;
  final String itemName;
  final double itemAmount;
  final bool itemStatus;
  final Timestamp timestamp;

  ItemMasterData({
    required this.itemCode,
    required this.itemName,
    required this.itemAmount,
    required this.itemStatus,
    required this.timestamp,
  });

  // convert data from firestore to a ItemMasterData object
  factory ItemMasterData.fromFirestore(Map<String, dynamic> data) {
    return ItemMasterData(
      itemCode: data['item_code'] ?? 0,
      itemName: data['item_name'] ?? '',
      itemAmount: data['item_amount'] ?? 0.0,
      itemStatus: data['item_status'] ?? true,
      timestamp: data['timestamp'],
    );
  }

  // convert a itemmasterdata object into a map object for firebase
  Map<String, dynamic> toFirestore() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'item_amount': itemAmount,
      'item_status': itemStatus,
      'timestamp': timestamp,
    };
  }
}
