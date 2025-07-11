import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/modals/item_master_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseService();

  // add item master data to firestore
  Future<bool> addItemMasterData(ItemMasterData itemMasterData) async {
    try {
      await _db
          .collection('item_master_data')
          .add(itemMasterData.toFirestore());
      return true;
    } catch (e) {
      print('Error adding item master data: $e');
      return false;
    }
  }

  // fetch itemmasterdata by itemcode
  Future<ItemMasterData?> getItemByItemCode(int itemCode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('item_master_data')
        .where('item_code', isEqualTo: itemCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ItemMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch itemmasterdata by itemname
  Future<ItemMasterData?> getItemByItemName(String itemName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('item_master_data')
        .where('item_name', isEqualTo: itemName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ItemMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch all Items
  Future<List<ItemMasterData>> getAllItems() async {
    try {
      QuerySnapshot snapshot = await _db.collection('item_master_data').get();

      return snapshot.docs
          .map(
            (doc) => ItemMasterData.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching all items: $e');
      return [];
    }
  }

  // update item master data by item code
  Future<bool> updateItemMasterDataByItemCode(
    String oldItemCode,
    ItemMasterData updatedData,
  ) async {
    try {
      // First check if the new no is already taken by another item
      if (oldItemCode != updatedData.itemCode) {
        QuerySnapshot duplicateCheck = await _db
            .collection('item_master_data')
            .where('item_code', isEqualTo: updatedData.itemCode)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          print('Error: Item Name ${updatedData.itemCode} already exists');
          return false;
        }
      }

      // FInd the document by the old item code
      QuerySnapshot snapshot = await _db
          .collection('item_master_data')
          .where('item_code', isEqualTo: oldItemCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('item_master_data').doc(docId).update({
          'item_code': updatedData.itemCode,
          'item_name': updatedData.itemName,
          'item_amount': updatedData.itemAmount,
          'item_status': updatedData.itemStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating item data: $e');
      return false;
    }
  }

  // update item master data
  Future<bool> updateItemMasterDataByItemName(
    String oldItemName,
    ItemMasterData updatedData,
  ) async {
    try {
      // First check if the new no is already taken by another item
      if (oldItemName != updatedData.itemName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('item_master_data')
            .where('item_name', isEqualTo: updatedData.itemName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          print('Error: Item Name ${updatedData.itemName} already exists');
          return false;
        }
      }

      // FInd the document by the old name
      QuerySnapshot snapshot = await _db
          .collection('item_master_data')
          .where('item_name', isEqualTo: oldItemName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('item_master_data').doc(docId).update({
          'item_code': updatedData.itemCode,
          'item_name': updatedData.itemName,
          'item_amount': updatedData.itemAmount,
          'item_status': updatedData.itemStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating item data: $e');
      return false;
    }
  }
}
