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
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> tables = [];

  bool isLoading = false;
  bool hasFetchedItems = false;
  bool hasFetchedSuppliers = false;
  bool hasFetchedTables = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      switch (widget.masterType) {
        case 'item':
          await _fetchItems();
          break;
        case 'supplier':
          await _fetchSuppliers();
          break;
        case 'table':
          await _fetchTables();
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('item_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['item_name'] as String? ?? '',
            'code': data['item_code'] as int? ?? 0,
            'amount': data['item_amount'] as double? ?? 0.0,
            'status': data['item_status'] as bool? ?? false,
          };
        }).toList();
        hasFetchedItems = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching items: $e')));
    }
  }

  Future<void> _fetchSuppliers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('supplier_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        suppliers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['supplier_name'] as String? ?? '',
            'contact': data['mobile_number'] as String? ?? '',
          };
        }).toList();
        hasFetchedSuppliers = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching suppliers: $e')));
    }
  }

  Future<void> _fetchTables() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('table_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        tables = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'number': data['table_number'] as int? ?? 0,
            'capacity': data['table_capacity'] as int? ?? 0,
            'status': data['table_availability'] as bool? ?? false,
          };
        }).toList();
        hasFetchedTables = true;
      });
    } catch (e) {
      if (!mounted) return;
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

  String _getPageTitle() {
    switch (widget.masterType) {
      case 'item':
        return 'Item Master';
      case 'supplier':
        return 'Supplier Master';
      case 'table':
        return 'Table Master';
      default:
        return 'Master Data';
    }
  }

  Widget _buildContent() {
    switch (widget.masterType) {
      case 'item':
        return _buildMasterList(
          header: const ['Item Name', 'Code', 'Price'],
          data: items,
          nameKey: 'name',
          secondaryKey: 'code',
          tertiaryKey: 'amount',
          statusKey: 'status',
          icon: Icons.fastfood,
          valueFormatter: (value) => '₹${value.toStringAsFixed(2)}',
        );
      case 'supplier':
        return _buildMasterList(
          header: const ['Supplier Name', 'Contact'],
          data: suppliers,
          nameKey: 'name',
          secondaryKey: 'contact',
          icon: Icons.business,
        );
      case 'table':
        return _buildMasterList(
          header: const ['Table No.', 'Capacity', 'Status'],
          data: tables,
          nameKey: 'number',
          secondaryKey: 'capacity',
          statusKey: 'status',
          icon: Icons.table_restaurant,
          valueFormatter: (value) => '$value persons',
        );
      default:
        return const Center(child: Text('Select a master type'));
    }
  }

  Widget _buildMasterList({
    required List<String> header,
    required List<Map<String, dynamic>> data,
    required String nameKey,
    required String secondaryKey,
    String? tertiaryKey,
    String? statusKey,
    required IconData icon,
    String Function(dynamic)? valueFormatter,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${widget.masterType}s available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  header[0],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  header[1],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (tertiaryKey != null)
                Expanded(
                  flex: 2,
                  child: Text(
                    header[2],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
        const Divider(thickness: 1.5, color: Colors.blueGrey),
        // Data List
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isActive = statusKey != null
                  ? (item[statusKey] as bool? ?? false)
                  : true;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: () => _navigateToViewPage(item[nameKey]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(
                        icon,
                        color: isActive ? Colors.blue.shade800 : Colors.grey,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item[nameKey].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item[secondaryKey].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive ? Colors.black54 : Colors.grey,
                              ),
                            ),
                          ),
                          if (tertiaryKey != null)
                            Expanded(
                              flex: 2,
                              child: Text(
                                valueFormatter != null
                                    ? valueFormatter(item[tertiaryKey])
                                    : item[tertiaryKey].toString(),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? Colors.blue.shade800
                                      : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: statusKey != null
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            )
                          : null,
                      subtitle: statusKey != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
