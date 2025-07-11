import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisplayFetchPage extends StatefulWidget {
  final String masterType;

  const DisplayFetchPage({super.key, required this.masterType});

  @override
  State<DisplayFetchPage> createState() => _DisplayFetchPageState();
}

class _DisplayFetchPageState extends State<DisplayFetchPage> {
  List<String> itemNames = [];
  List<String> supplierNames = [];
  List<int> tableNumbers = [];

  bool isLoading = false;
  bool hasFetchedItems = false;
  bool hasFetchedSuppliers = false;
  bool hasFetchedTableNumbers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      switch (widget.masterType) {
        case 'item':
          await _fetchItemNames();
          break;
        case 'supplier':
          await _fetchSupplierNames();
          break;
        case 'table':
          await _fetchTableNumbers();
          break;
        default:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchItemNames() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('item_master_data')
          .get();

      setState(() {
        itemNames = snapshot.docs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['item_name'] as String,
            )
            .toList();
        hasFetchedItems = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching items: $e')));
    }
  }

  Future<void> _fetchSupplierNames() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('supplier_master_data')
          .get();

      setState(() {
        supplierNames = snapshot.docs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['supplier_name']
                      as String,
            )
            .toList();
        hasFetchedSuppliers = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching suppliers: $e')));
    }
  }

  Future<void> _fetchTableNumbers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('table_master_data')
          .get();

      setState(() {
        tableNumbers = snapshot.docs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['table_number'] as int,
            )
            .toList();
        hasFetchedTableNumbers = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching tables: $e')));
    }
  }

  void _navigateToViewPage(dynamic value) {
    switch (widget.masterType) {
      case 'item':
        context.go(
          '/item_master',
          extra: {'itemName': value, 'isDisplayMode': true},
        );
        break;
      case 'supplier':
        context.go(
          '/supplier_master',
          extra: {'supplierName': value, 'isDisplayMode': true},
        );
        break;
      case 'table':
        context.go(
          '/table_master',
          extra: {'tableNumber': value, 'isDisplayMode': true},
        );
        break;
      default:
        break;
    }
  }

  String _getPageTitle() {
    switch (widget.masterType) {
      case 'item':
        return 'Item Master';
      case 'supplier':
        return 'Supplier Master';
      case 'table':
        return 'Table Master';
      default:
        return 'Display Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: widget.masterType),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    switch (widget.masterType) {
      case 'item':
        return _buildItemNamesList();
      case 'supplier':
        return _buildSupplierNamesList();
      case 'table':
        return _buildTableNumbersList();
      default:
        return const Center(child: Text('Select a master type first'));
    }
  }

  Widget _buildItemNamesList() {
    if (!hasFetchedItems) {
      return _buildInitialState('items');
    }
    return itemNames.isEmpty
        ? const Center(child: Text('No items available'))
        : ListView.builder(
            itemCount: itemNames.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(itemNames[index]),
                  leading: const Icon(Icons.fastfood),
                  onTap: () => _navigateToViewPage(itemNames[index]),
                ),
              );
            },
          );
  }

  Widget _buildSupplierNamesList() {
    if (!hasFetchedSuppliers) {
      return _buildInitialState('suppliers');
    }
    return supplierNames.isEmpty
        ? const Center(child: Text('No suppliers available'))
        : ListView.builder(
            itemCount: supplierNames.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(supplierNames[index]),
                  leading: const Icon(Icons.business),
                  onTap: () => _navigateToViewPage(supplierNames[index]),
                ),
              );
            },
          );
  }

  Widget _buildTableNumbersList() {
    if (!hasFetchedTableNumbers) {
      return _buildInitialState('tables');
    }
    return tableNumbers.isEmpty
        ? const Center(child: Text('No tables available'))
        : ListView.builder(
            itemCount: tableNumbers.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text('Table ${tableNumbers[index]}'),
                  leading: const Icon(Icons.table_restaurant),
                  onTap: () => _navigateToViewPage(tableNumbers[index]),
                ),
              );
            },
          );
  }

  Widget _buildInitialState(String dataType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No $dataType loaded'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Load Data')),
        ],
      ),
    );
  }
}
