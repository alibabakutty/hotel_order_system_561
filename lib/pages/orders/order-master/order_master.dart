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
  bool _isLoadingTables = false;
  TableMasterData? _selectedTable;
  final FirebaseService _firebaseService = FirebaseService();
  List<ItemMasterData> _allItems = [];
  bool _isLoadingItems = false;
  bool _isGuestInfoExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchSupplierData();
    _loadAllItems();
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

  void _submitOrder() {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order submitted for Table ${_selectedTable?.tableNumber ?? 'No Table'}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        orderItems = [OrderItemExtension.empty()];
        _selectedTable = null;
        _quantityController.clear();
        _maleController.clear();
        _femaleController.clear();
        _kidsController.clear();
      });
    }
  }

  void _onTableSelected(TableMasterData? table) {
    setState(() {
      _selectedTable = table;
      if (table == null) {
        _showTableAllocation = false;
      }
    });

    if (table != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${table.tableNumber} selected (Capacity: ${table.tableCapacity})',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
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
                                                  width: 140,
                                                  child: const Text(
                                                    'ITEM',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 65,
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
                                                const SizedBox(width: 6),
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
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 25,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => setState(
                                                      () => orderItems.insert(
                                                        0,
                                                        OrderItemExtension.empty(),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.add,
                                                      size: 15,
                                                    ),
                                                    label: const Text(''),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          minimumSize:
                                                              Size.zero,
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
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),
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
