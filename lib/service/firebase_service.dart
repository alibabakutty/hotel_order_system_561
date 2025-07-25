import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/order_item_data.dart';
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

  // Add complete order with items to Firestore
  Future<bool> addOrderMasterData({
    required List<OrderItem> orderItems,
    required TableMasterData table,
    required String orderNumber,
    required double totalQty,
    required double totalAmount,
    required int maleCount,
    required int femaleCount,
    required int kidsCount,
    required String supplierName, // 👈 New parameter
  }) async {
    try {
      int guestCount = maleCount + femaleCount + kidsCount;

      DocumentReference orderRef = await _db.collection('orders').add({
        'order_number': orderNumber,
        'table_number': table.tableNumber,
        'supplier_name': supplierName, // 👈 Save to Firestore
        'total_quantity': totalQty,
        'total_amount': totalAmount,
        'guest_count': guestCount,
        'male_count': maleCount,
        'female_count': femaleCount,
        'kids_count': kidsCount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (OrderItem item in orderItems) {
        // calculate net amount before storing
        double netAmount = item.quantity * item.itemRateAmount;
        // Get the base item data
        Map<String, dynamic> itemData = item.toFirestore();
        // override the netamount
        itemData['itemNetAmount'] = netAmount;
        // now store in firestore
        await orderRef.collection('items').add(itemData);
      }

      return true;
    } catch (e) {
      print('Error adding full order data: $e');
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

  // Update return type and conversion
  Future<List<Map<String, dynamic>>> getOrdersByDate(String dateString) async {
    final date = DateTime.parse(dateString);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id, // Include the document ID
        ...data,
      };
    }).toList();
  }

  // Similarly update the other methods
  Future<List<Map<String, dynamic>>> getOrdersByDateRange(
    String startDateString,
    String endDateString,
  ) async {
    try {
      DateTime startDate = DateTime.parse(startDateString);
      DateTime endDate = DateTime.parse(endDateString);
      DateTime adjustedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: adjustedEndDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching orders by date range: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredOrders({
    String? dateString,
    String? supplierName,
    int? tableNumber,
  }) async {
    try {
      Query query = _db.collection('orders');

      if (dateString != null) {
        DateTime date = DateTime.parse(dateString);
        DateTime startOfDay = DateTime(date.year, date.month, date.day);
        DateTime endOfDay = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        );
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
            .where('timestamp', isLessThanOrEqualTo: endOfDay);
      }

      if (supplierName != null) {
        query = query.where('supplier_name', isEqualTo: supplierName);
      }

      if (tableNumber != null) {
        query = query.where('table_number', isEqualTo: tableNumber);
      }

      query = query.orderBy('timestamp', descending: true);

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching filtered orders: $e');
      return [];
    }
  }

  // Add this to your firebase_service.dart
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw 'Error fetching order items: $e';
    }
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

  // Fetch all orders from Firestore
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .orderBy('timestamp', descending: true) // Most recent first
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all orders: $e');
      return [];
    }
  }

  // Fetch all orders with their items
  Future<List<Map<String, dynamic>>> getAllOrdersWithItems() async {
    try {
      QuerySnapshot ordersSnapshot = await _db
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> orders = [];

      for (var orderDoc in ordersSnapshot.docs) {
        // Get order data
        Map<String, dynamic> orderData =
            orderDoc.data() as Map<String, dynamic>;
        orderData['id'] = orderDoc.id;

        // Get items for this order
        QuerySnapshot itemsSnapshot = await orderDoc.reference
            .collection('items')
            .get();
        List<Map<String, dynamic>> items = itemsSnapshot.docs
            .map((itemDoc) => itemDoc.data() as Map<String, dynamic>)
            .toList();

        orderData['items'] = items;
        orders.add(orderData);
      }

      return orders;
    } catch (e) {
      print('Error fetching all orders with items: $e');
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
          'item_rate_amount': updatedData.itemRateAmount,
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
          'item_rate_amount': updatedData.itemRateAmount,
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
