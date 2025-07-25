import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_order_system/service/firebase_service.dart';
import 'package:intl/intl.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';

  // Date filters
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _specificDate = DateTime.now();
  String _searchType = 'date';

  // Other filters
  String? _selectedSupplier;
  int? _selectedTableNumber;
  List<String> _suppliers = [];
  List<int> _tableNumbers = [];

  // Table configuration
  List<String> _selectedColumns = [
    'Date',
    'Order #',
    'Table',
    'Supplier',
    'Total',
    'Status',
  ];
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load suppliers and table numbers for dropdowns
      final suppliers = await _firebaseService.getAllSuppliers();
      final tables = await _firebaseService.getAllTables();

      setState(() {
        _suppliers = suppliers.map((s) => s.supplierName).toList();
        _tableNumbers = tables.map((t) => t.tableNumber).toList();
      });

      // Load today's orders by default
      await _fetchOrders(dateString: DateTime.now().toString());
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading initial data: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders({
    String? dateString,
    String? startDateString,
    String? endDateString,
    String? supplierName,
    int? tableNumber,
  }) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
      _orders.clear();
    });

    try {
      List<Map<String, dynamic>> orders;

      if (dateString != null) {
        // Fetch by single date
        orders = await _firebaseService.getOrdersByDate(dateString);
      } else if (startDateString != null && endDateString != null) {
        // Fetch by date range
        orders = await _firebaseService.getOrdersByDateRange(
          startDateString,
          endDateString,
        );
      } else {
        // Fetch with filters
        orders = await _firebaseService.getFilteredOrders(
          dateString: dateString,
          supplierName: supplierName,
          tableNumber: tableNumber,
        );
      }

      setState(() {
        _orders = orders;
        if (orders.isEmpty) {
          _errorMessage = 'No orders found';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching orders: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    bool isStartDate = false,
    bool isEndDate = false,
    bool isSpecificDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isSpecificDate
          ? _specificDate ?? DateTime.now()
          : isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSpecificDate) {
          _specificDate = picked;
        } else if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildSearchTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _searchType,
      decoration: InputDecoration(
        labelText: 'Search By',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'date', child: Text('Date')),
        DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
        DropdownMenuItem(value: 'table', child: Text('Table Number')),
      ],
      onChanged: (value) {
        setState(() {
          _searchType = value!;
          _hasSearched = false;
          _orders.clear();
          _errorMessage = '';
          _selectedSupplier = null;
          _selectedTableNumber = null;
          _specificDate = null;
          _startDate = null;
          _endDate = null;
        });
      },
    );
  }

  Widget _buildDateSearchOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Specific Date',
                  style: TextStyle(fontSize: 14),
                ),
                value: 'specific',
                groupValue:
                    _specificDate != null ||
                        (_startDate == null && _endDate == null)
                    ? 'specific'
                    : 'range',
                onChanged: (value) {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    if (_specificDate == null) {
                      _specificDate = DateTime.now();
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date Range', style: TextStyle(fontSize: 14)),
                value: 'range',
                groupValue: _startDate != null || _endDate != null
                    ? 'range'
                    : 'specific',
                onChanged: (value) {
                  setState(() {
                    _specificDate = null;
                    if (_startDate == null) _startDate = DateTime.now();
                    if (_endDate == null) _endDate = DateTime.now();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_specificDate != null) _buildSpecificDateSelector(),
        if (_startDate != null && _endDate != null) _buildDateRangeSelector(),
      ],
    );
  }

  Widget _buildSpecificDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectDate(context, isSpecificDate: true),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Select Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: Text(
              _specificDate != null
                  ? DateFormat('dd-MM-yyyy').format(_specificDate!)
                  : 'Select a date',
              style: TextStyle(
                fontSize: 14,
                color: _specificDate != null
                    ? Colors.black87
                    : Colors.grey[600],
                fontWeight: _specificDate != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _specificDate != null
                ? () => _fetchOrders(dateString: _specificDate.toString())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Search by Specific Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectDate(context, isStartDate: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('dd-MM-yyyy').format(_startDate!)
                        : 'Select start date',
                    style: TextStyle(
                      fontSize: 14,
                      color: _startDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: _startDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectDate(context, isEndDate: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('dd-MM-yyyy').format(_endDate!)
                        : 'Select end date',
                    style: TextStyle(
                      fontSize: 14,
                      color: _endDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: _endDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_startDate != null && _endDate != null)
                ? () => _fetchOrders(
                    startDateString: _startDate.toString(),
                    endDateString: _endDate.toString(),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Search by Date Range',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierSearchOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedSupplier,
          decoration: InputDecoration(
            labelText: 'Select Supplier',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: _suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier,
              child: Text(supplier, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedSupplier = value);
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedSupplier != null
                ? () => _fetchOrders(supplierName: _selectedSupplier)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Search by Supplier',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSearchOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _selectedTableNumber,
          decoration: InputDecoration(
            labelText: 'Select Table Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: _tableNumbers.map((table) {
            return DropdownMenuItem(
              value: table,
              child: Text(
                table.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedTableNumber = value);
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedTableNumber != null
                ? () => _fetchOrders(tableNumber: _selectedTableNumber)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Search by Table',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInputFields() {
    switch (_searchType) {
      case 'supplier':
        return _buildSupplierSearchOptions();
      case 'table':
        return _buildTableSearchOptions();
      case 'date':
      default:
        return _buildDateSearchOptions();
    }
  }

  Widget _buildColumnSelector() {
    return PopupMenuButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 18),
            SizedBox(width: 4),
            Text('Columns', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          child: Text(
            'Select Columns',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ..._allAvailableColumns.map((column) {
          return PopupMenuItem(
            child: CheckboxListTile(
              title: Text(column, style: const TextStyle(fontSize: 14)),
              value: _selectedColumns.contains(column),
              onChanged: (selected) {
                setState(() {
                  if (selected!) {
                    _selectedColumns.add(column);
                  } else {
                    _selectedColumns.remove(column);
                  }
                });
                Navigator.pop(context);
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          );
        }).toList(),
      ],
    );
  }

  List<String> get _allAvailableColumns => [
    'Date',
    'Order #',
    'Table',
    'Supplier',
    'Total',
    'Status',
    'Guests',
    'Items Count',
    'Payment Method',
  ];

  List<DataColumn> _buildDataColumns() {
    return _selectedColumns.map((column) {
      return DataColumn(
        label: Text(column, style: const TextStyle(fontSize: 12)),
        tooltip: column,
        onSort: (columnIndex, ascending) {
          _onSort(columnIndex, ascending);
        },
      );
    }).toList();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      String column = _selectedColumns[columnIndex];
      _orders.sort((a, b) {
        int compareResult;
        switch (column) {
          case 'Date':
            compareResult = (a['timestamp'] as Timestamp).compareTo(
              b['timestamp'] as Timestamp,
            );
            break;
          case 'Order #':
            compareResult = (a['order_number'] ?? '').compareTo(
              b['order_number'] ?? '',
            );
            break;
          case 'Table':
            compareResult = (a['table_number'] ?? 0).compareTo(
              b['table_number'] ?? 0,
            );
            break;
          case 'Supplier':
            compareResult = (a['supplier_name'] ?? '').compareTo(
              b['supplier_name'] ?? '',
            );
            break;
          case 'Total':
            compareResult = (a['total_amount'] ?? 0.0).compareTo(
              b['total_amount'] ?? 0.0,
            );
            break;
          case 'Status':
            compareResult = (a['status'] ?? '').compareTo(b['status'] ?? '');
            break;
          case 'Guests':
            compareResult = (a['guest_count'] ?? 0).compareTo(
              b['guest_count'] ?? 0,
            );
            break;
          case 'Items Count':
            compareResult = ((a['items'] as List).length).compareTo(
              (b['items'] as List).length,
            );
            break;
          case 'Payment Method':
            compareResult = (a['payment_method'] ?? '').compareTo(
              b['payment_method'] ?? '',
            );
            break;
          default:
            compareResult = 0;
        }
        return ascending ? compareResult : -compareResult;
      });
    });
  }

  List<DataRow> _buildDataRows() {
    return _orders.map((order) {
      final cells = _selectedColumns.map((column) {
        return DataCell(_buildCellContent(column, order));
      }).toList();

      return DataRow(
        cells: cells,
        color: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return _orders.indexOf(order) % 2 == 0
              ? Colors.white
              : Colors.grey.shade50;
        }),
        onSelectChanged: (selected) {
          if (selected == true) {
            _showOrderDetails(order);
          }
        },
      );
    }).toList();
  }

  Widget _buildCellContent(String column, Map<String, dynamic> order) {
    switch (column) {
      case 'Date':
        return Text(
          DateFormat('dd-MM-yyyy HH:mm').format(order['timestamp'].toDate()),
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Order #':
        return Text(
          order['order_number']?.toString() ?? 'N/A',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Table':
        return Text(
          order['table_number']?.toString() ?? 'N/A',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Supplier':
        return Text(
          order['supplier_name'] ?? 'N/A',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Total':
        return Text(
          '₹${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Status':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(order['status']).withAlpha(51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(order['status']),
              width: 1,
            ),
          ),
          child: Text(
            (order['status'] ?? 'N/A').toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(order['status']),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        );
      case 'Guests':
        return Text(
          order['guest_count']?.toString() ?? '0',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      case 'Items Count':
        return FutureBuilder<int>(
          future: _getItemsCount(
            order['id'] ?? order['order_number'].toString(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                '...',
                style: TextStyle(fontSize: 12, height: 1.1),
              );
            }
            return Text(
              snapshot.data?.toString() ?? '0',
              style: const TextStyle(fontSize: 12, height: 1.1),
            );
          },
        );
      case 'Payment Method':
        return Text(
          order['payment_method'] ?? 'N/A',
          style: const TextStyle(fontSize: 12, height: 1.1),
        );
      default:
        return const Text('N/A', style: TextStyle(fontSize: 12, height: 1.1));
    }
  }

  Future<int> _getItemsCount(String orderId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .count()
          .get();
      return querySnapshot.count!;
    } catch (e) {
      return 0;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (_orders.isEmpty && _hasSearched) {
      return const Center(
        child: Text(
          'No orders found',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildColumnSelector()],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DataTable(
              headingRowHeight: 36,
              dataRowHeight: 32,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) => Colors.orange.shade100,
              ),
              columns: _buildDataColumns(),
              rows: _buildDataRows(),
              dividerThickness: 1,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
                height: 1.1,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
          ),
        ),
        if (_orders.isNotEmpty) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export functionality coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text(
              'Export to Excel',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        // Fetch items when dialog opens
        Future<List<Map<String, dynamic>>> itemsFuture = _firebaseService
            .getOrderItems(order['id'] ?? order['order_number'].toString());

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: itemsFuture,
          builder: (context, snapshot) {
            List<Map<String, dynamic>> items = [];
            bool isLoadingItems =
                snapshot.connectionState == ConnectionState.waiting;
            String? errorMessage;

            if (snapshot.hasError) {
              errorMessage = snapshot.error.toString();
            } else if (snapshot.hasData) {
              items = snapshot.data!;
            }

            return AlertDialog(
              title: Text('Order #${order['order_number']}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      'Date',
                      DateFormat(
                        'dd-MM-yyyy HH:mm',
                      ).format(order['timestamp'].toDate()),
                    ),
                    _buildDetailRow(
                      'Table',
                      order['table_number']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Supplier',
                      order['supplier_name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Status',
                      order['status'] ?? 'N/A',
                      isStatus: true,
                    ),
                    _buildDetailRow(
                      'Payment Method',
                      order['payment_method'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Total',
                      '₹${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                    _buildDetailRow(
                      'Guests',
                      '${order['guest_count'] ?? 0} (M: ${order['male_count'] ?? 0}, F: ${order['female_count'] ?? 0}, K: ${order['kids_count'] ?? 0})',
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Order Items:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (isLoadingItems)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error loading items: $errorMessage',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No items found'),
                      )
                    else
                      ...items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '- ${item['name'] ?? item['itemName'] ?? 'Unnamed Item'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'x${item['quantity']?.toString() ?? '1'}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${(item['itemNetAmount'] ?? 0.0).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withAlpha(51),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(value), width: 1),
              ),
              child: Text(
                value.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(value),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        title: const Text('Order History', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchTypeSelector(),
              const SizedBox(height: 12),
              _buildSearchInputFields(),
              const SizedBox(height: 12),
              _buildOrderList(),
            ],
          ),
        ),
      ),
    );
  }
}
