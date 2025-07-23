import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/order_item_data.dart';
import 'package:food_order_system/models/table_master_data.dart';
import 'package:food_order_system/pages/orders/allocate_table_section.dart';
import 'package:food_order_system/pages/orders/guest_info_section.dart';
import 'package:food_order_system/pages/orders/order-master/order_item_row.dart';
import 'package:food_order_system/pages/orders/order-master/order_utils.dart';
import 'package:food_order_system/service/firebase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderMaster extends StatefulWidget {
  final AuthService authService;
  const OrderMaster({super.key, required this.authService});

  @override
  State<OrderMaster> createState() => _OrderMasterState();
}

class _OrderMasterState extends State<OrderMaster> {
  String? supplierUsername;
  bool isLoading = true;
  List<OrderItem> orderItems = [OrderItemExtension.empty()];

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _kidsController = TextEditingController();

  bool _showTableAllocation = false;
  final _isLoadingTables = false;
  TableMasterData? _selectedTable;
  final FirebaseService _firebaseService = FirebaseService();
  List<ItemMasterData> _allItems = [];
  bool _isLoadingItems = false;
  bool _isGuestInfoExpanded = true;

  // order number tracking
  int _orderCounter = 0;
  String _currentOrderNumber = '';
  DateTime? _lastResetDate;

  @override
  void initState() {
    super.initState();
    _loadOrderCounter();
    _fetchSupplierData();
    _loadAllItems();
  }

  Future<void> _loadOrderCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString('lastResetDate');
    final savedCounter = prefs.getInt('orderCounter') ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }

    // Reset counter if it's a new day
    if (_lastResetDate == null || today.isAfter(_lastResetDate!)) {
      setState(() {
        _orderCounter = 0;
        _lastResetDate = today;
      });
      await prefs.setInt('orderCounter', 0);
      await prefs.setString('lastResetDate', today.toIso8601String());
    } else {
      setState(() {
        _orderCounter = savedCounter;
      });
    }
  }

  Future<void> _saveOrderCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('orderCounter', _orderCounter);
    if (_lastResetDate != null) {
      await prefs.setString('lastResetDate', _lastResetDate!.toIso8601String());
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Reset counter if it's a new day
    if (_lastResetDate == null || today.isAfter(_lastResetDate!)) {
      _orderCounter = 0;
      _lastResetDate = today;
      _saveOrderCounter();
    }
    _orderCounter++;
    _saveOrderCounter();
    return 'DINE-${_orderCounter.toString().padLeft(4, '0')}';
  }

  void _addNewRow() {
    setState(() {
      orderItems.add(OrderItem.empty());
    });
  }

  Future<void> _fetchSupplierData() async {
    try {
      final authUser = await widget.authService.getCurrentAuthUser();
      if (authUser.role != UserRole.supplier) {
        if (mounted) context.go('/supplier_login');
        return;
      }

      setState(() {
        supplierUsername = authUser.supplierName ?? 'Supplier';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/supplier_login');
      }
    }
  }

  Future<void> _loadAllItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await _firebaseService.getAllItems();
      setState(() => _allItems = items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.authService.signOut();
      if (mounted) context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMemberDistributionDialog() {
    final totalMembers = int.tryParse(_quantityController.text) ?? 0;
    bool maleEntered = false, femaleEntered = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateCounts({String? changedField}) {
            int male = int.tryParse(_maleController.text) ?? 0;
            int female = int.tryParse(_femaleController.text) ?? 0;

            if (changedField == 'male')
              maleEntered = _maleController.text.isNotEmpty;
            if (changedField == 'female')
              femaleEntered = _femaleController.text.isNotEmpty;

            if (maleEntered && femaleEntered) {
              int kids = totalMembers - male - female;
              _kidsController.text = kids >= 0 ? kids.toString() : '0';
              if (kids < 0) _femaleController.text = (female + kids).toString();
            }
          }

          return AlertDialog(
            title: Text('Distribute $totalMembers Members'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _maleController,
                    decoration: const InputDecoration(
                      labelText: 'Male Count',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.man),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateCounts(changedField: 'male'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _femaleController,
                    decoration: const InputDecoration(
                      labelText: 'Female Count',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.woman),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => updateCounts(changedField: 'female'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _kidsController,
                    decoration: const InputDecoration(
                      labelText: 'Kids Count (Auto)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.child_care),
                      filled: true,
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  int male = int.tryParse(_maleController.text) ?? 0;
                  int female = int.tryParse(_femaleController.text) ?? 0;
                  int kids = int.tryParse(_kidsController.text) ?? 0;

                  if (male + female + kids == totalMembers) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saved: $male Male, $female Female, $kids Kids',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Total must match member count'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      if (orderItems.isEmpty ||
          (orderItems.length == 1 && orderItems[0].itemCode.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a table first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order $_currentOrderNumber for Table ${_selectedTable!.tableNumber} submitted successfully!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        orderItems = [OrderItemExtension.empty()];
        // Don't clear table or order number - keep them for next order
        _quantityController.clear();
        _maleController.clear();
        _femaleController.clear();
        _kidsController.clear();
      });
    }
  }

  void _onTableSelected(TableMasterData? table) {
    if (table != null && _selectedTable?.tableNumber != table.tableNumber) {
      // Generate new order number when a new table is selected
      setState(() {
        _selectedTable = table;
        _currentOrderNumber = _generateOrderNumber();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${table.tableNumber} selected - Order $_currentOrderNumber created',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (table == null) {
      setState(() {
        _selectedTable = null;
        _showTableAllocation = false;
      });
    }
  }

  // Helper methods to calculate totals
  double get _totalQuantity {
    return orderItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalAmount {
    return orderItems.fold(
      0,
      (sum, item) => sum + (item.itemRateAmount * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, _) =>
                      Text('${TimeOfDay.now().format(context)}  '),
                ),
                Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                ),
              ],
            ),
            Text(
              'Make Order - ${getDisplayName(supplierUsername ?? 'Supplier')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout ${supplierUsername ?? 'Supplier'}',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Guest Info Section
              GuestInfoSection(
                quantityController: _quantityController,
                maleController: _maleController,
                femaleController: _femaleController,
                kidsController: _kidsController,
                onDistributePressed: _showMemberDistributionDialog,
                onTableAllocatePressed: () {
                  setState(() {
                    _showTableAllocation = true;
                    _isGuestInfoExpanded = true;
                  });
                },
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    _isGuestInfoExpanded = isExpanded;
                    if (!isExpanded) {
                      _showTableAllocation = false;
                    }
                  });
                },
                selectedTable: _selectedTable?.tableNumber.toString(),
                totalMembers: int.tryParse(_quantityController.text),
                orderNumber: _currentOrderNumber,
              ),

              // Table Allocation Section
              if (_isGuestInfoExpanded && _showTableAllocation) ...[
                const SizedBox(height: 8),
                _isLoadingTables
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                        child: AllocateTableSection(
                          selectedTable: _selectedTable,
                          onTableSelected: _onTableSelected,
                        ),
                      ),
              ],

              // Order Items Section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Scrollable(
                                axisDirection: AxisDirection.right,
                                viewportBuilder: (context, offset) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: MediaQuery.of(
                                          context,
                                        ).size.width,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                              horizontal: 2.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            width: 1000,
                                            height: 30,
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  child: const Text(
                                                    'S.No.',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 115,
                                                  child: const Text(
                                                    'PRODUCT NAME',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 45,
                                                  child: const Text(
                                                    'QTY',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 50,
                                                  child: const Text(
                                                    'RATE',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 70,
                                                  child: const Text(
                                                    'AMOUNT',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          for (
                                            int i = 0;
                                            i < orderItems.length;
                                            i++
                                          )
                                            OrderItemRow(
                                              index: i,
                                              item: orderItems[i],
                                              allItems: _allItems,
                                              isLoadingItems: _isLoadingItems,
                                              onRemove: (index) => setState(
                                                () =>
                                                    orderItems.removeAt(index),
                                              ),
                                              onUpdate: (index, updatedItem) =>
                                                  setState(
                                                    () => orderItems[index] =
                                                        updatedItem,
                                                  ),
                                              onItemSelected: () => setState(() {
                                                // onaly add new row if this is the last item and it's not empty
                                                if (i ==
                                                        orderItems.length - 1 &&
                                                    orderItems[i]
                                                        .itemCode
                                                        .isNotEmpty) {
                                                  orderItems.add(
                                                    OrderItemExtension.empty(),
                                                  );
                                                }
                                              }),
                                              onAddNewRow: _addNewRow,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),
                              // Totals Display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Items: ${_totalQuantity.toStringAsFixed(_totalQuantity % 1 == 0 ? 0 : 2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total Amount: ₹${_totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _submitOrder,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Submit Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _kidsController.dispose();
    super.dispose();
  }
}
