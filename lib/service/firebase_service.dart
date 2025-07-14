import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/supplier_master_data.dart';
import 'package:food_order_system/models/table_master_data.dart';

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

  // add supplier master data to firestore
  Future<bool> addSupplierMasterData(
    SupplierMasterData supplierMasterData,
  ) async {
    try {
      await _db
          .collection('supplier_master_data')
          .add(supplierMasterData.toFirestore());
      return true;
    } catch (e) {
      print('Error adding supplier master data: $e');
      return false;
    }
  }

  // add table master data to firestore
  Future<bool> addTableMasterData(TableMasterData tableMasterData) async {
    try {
      await _db
          .collection('table_master_data')
          .add(tableMasterData.tofirestore());
      return true;
    } catch (e) {
      print('Error adding table master data: $e');
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

  // fetch suppliermasterdata by suppliername
  Future<SupplierMasterData?> getSupplierBySupplierName(
    String supplierName,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('supplier_master_data')
        .where('supplier_name', isEqualTo: supplierName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SupplierMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch suppliermasterdata by mobileNumber
  Future<SupplierMasterData?> getSupplierByMobileNumber(
    String mobileNumber,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('supplier_master_data')
        .where('mobile_number', isEqualTo: mobileNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SupplierMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch tablemasterdata by tablenumber
  Future<TableMasterData?> getTableByTableNumber(int tableNumber) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('table_master_data')
        .where('table_number', isEqualTo: tableNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return TableMasterData.fromfirestore(snapshot.docs.first.data());
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

  // fetch all Suppliers
  Future<List<SupplierMasterData>> getAllSuppliers() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .get();

      return snapshot.docs
          .map(
            (doc) => SupplierMasterData.fromfirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching all suppliers: $e');
      return [];
    }
  }

  // fetch all tables
  Future<List<TableMasterData>> getAllTables() async {
    try {
      QuerySnapshot snapshot = await _db.collection('table_master_data').get();

      return snapshot.docs
          .map(
            (doc) => TableMasterData.fromfirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching all tables: $e');
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

  // update supplier master data by supplier name
  Future<bool> updateSupplierMasterDataBySupplierName(
    String oldSupplierName,
    SupplierMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another supplier
      if (oldSupplierName != updatedData.supplierName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('supplier_master_data')
            .where('supplier_name', isEqualTo: updatedData.supplierName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          print(
            'Error: Supplier name ${updatedData.supplierName} already exists',
          );
          return false;
        }
      }

      // Find the document by the old supplier name
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .where('supplier_name', isEqualTo: oldSupplierName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('supplier_master_data').doc(docId).update({
          'supplier_name': updatedData.supplierName,
          'mobile_number': updatedData.mobileNumber,
          'email': updatedData.email,
          'password': updatedData.password,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating supplier data: $e');
      return false;
    }
  }

  // update supplier master data by mobile number
  Future<bool> updateSupplierMasterDataByMobileNumber(
    String oldMobileNumber,
    SupplierMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another supplier
      if (oldMobileNumber != updatedData.mobileNumber) {
        QuerySnapshot duplicateCheck = await _db
            .collection('supplier_master_data')
            .where('mobile_number', isEqualTo: updatedData.mobileNumber)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          print(
            'Error: Supplier name ${updatedData.mobileNumber} already exists',
          );
          return false;
        }
      }

      // Find the document by the old supplier name
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .where('mobile_number', isEqualTo: oldMobileNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('supplier_master_data').doc(docId).update({
          'supplier_name': updatedData.supplierName,
          'mobile_number': updatedData.mobileNumber,
          'email': updatedData.email,
          'password': updatedData.password,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating supplier data: $e');
      return false;
    }
  }

  // update table master data by table number
  Future<bool> updateTableMasterDataByTableNumber(
    int oldTableNumber,
    TableMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another table number
      if (oldTableNumber != updatedData.tableNumber) {
        QuerySnapshot duplicateCheck = await _db
            .collection('table_master_data')
            .where('table_number', isEqualTo: updatedData.tableNumber)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          print(
            'Error: Table Number ${updatedData.tableNumber} already exists',
          );
          return false;
        }
      }

      // Find the document by the old table number
      QuerySnapshot snapshot = await _db
          .collection('table_master_data')
          .where('table_number', isEqualTo: oldTableNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('table_master_data').doc(docId).update({
          'table_number': updatedData.tableNumber,
          'table_capacity': updatedData.tableCapacity,
          'table_availability': updatedData.tableAvailability,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating table master data: $e');
      return false;
    }
  }
}
