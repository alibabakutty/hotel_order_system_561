import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/order_item_data.dart';
import 'package:food_order_system/models/table_master_data.dart';
import 'package:food_order_system/pages/orders/allocate_table_section.dart';
import 'package:food_order_system/pages/orders/guest_info_section.dart';
import 'package:food_order_system/service/firebase_service.dart';
import 'package:go_router/go_router.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class OrderMaster extends StatefulWidget {
  final AuthService authService;
  const OrderMaster({super.key, required this.authService});

  @override
  State<OrderMaster> createState() => _OrderMasterState();
}

class _OrderMasterState extends State<OrderMaster> {
  String? supplierUsername;
  bool isLoading = true;
  List<OrderItem> orderItems = [
    OrderItem(
      itemCode: '',
      itemName: '',
      itemAmount: 0.0,
      itemStatus: true,
      quantity: 1,
    ),
  ];

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
    setState(() {
      _isLoadingItems = true;
    });
    try {
      final items = await _firebaseService.getAllItems();
      setState(() {
        _allItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingItems = false;
      });
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
        orderItems = [OrderItem.empty()];
        _selectedTable = null;
        _quantityController.clear();
        _maleController.clear();
        _femaleController.clear();
        _kidsController.clear();
      });
    }
  }

  Future<void> _handleTableAllocation() async {
    if (_showTableAllocation) {
      setState(() => _showTableAllocation = false);
      return;
    }

    setState(() => _isLoadingTables = true);

    try {
      await _firebaseService.getAllTables();
      setState(() => _showTableAllocation = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tables: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingTables = false);
    }
  }

  void _onTableSelected(TableMasterData? table) {
    setState(() => _selectedTable = table);
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

  String _getDisplayName(String name) =>
      name.length <= 12 ? name : '${name.substring(0, 12)}...';

  Widget _buildOrderItemRow(int index, OrderItem item) {
    final itemNameController = TextEditingController(text: item.itemName);
    final focusNode = FocusNode();
    final quantityController = TextEditingController(
      text: item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2),
    );

    void updateQuantity(double newQty) {
      // For quantities less than 1, only allow 0.25, 0.50, 0.75
      if (newQty < 1) {
        newQty = (newQty * 4).round() / 4; // Snap to nearest 0.25
        newQty = newQty.clamp(
          0.25,
          0.75,
        ); // Ensure it stays between 0.25 and 0.75
      }
      // For quantities 1 and above, allow whole numbers only
      else {
        newQty = newQty.roundToDouble(); // Round to nearest whole number
      }

      // If trying to decrease below minimum, remove the item
      if (newQty <= 0.24) {
        setState(() => orderItems.removeAt(index));
        return;
      }

      setState(() {
        orderItems[index] = OrderItem(
          itemCode: item.itemCode,
          itemName: item.itemName,
          itemAmount: item.itemAmount,
          itemStatus: item.itemStatus,
          quantity: newQty,
        );
        quantityController.text = newQty % 1 == 0
            ? newQty.toInt().toString()
            : newQty.toStringAsFixed(2);
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      width: 1000,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item Name (searchable autocomplete or editable field)
          SizedBox(
            width: 105,
            height: 40,
            child: item.itemCode.isEmpty
                ? RawAutocomplete<ItemMasterData>(
                    focusNode: focusNode,
                    textEditingController: TextEditingController(),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return _isLoadingItems
                          ? const Iterable<ItemMasterData>.empty()
                          : _allItems.where(
                              (item) => item.itemName.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                    },
                    onSelected: (ItemMasterData selection) {
                      setState(() {
                        orderItems[index] = OrderItem(
                          itemCode: selection.itemCode.toString(),
                          itemName: selection.itemName.capitalize(),
                          itemAmount: selection.itemAmount,
                          itemStatus: selection.itemStatus,
                          quantity: orderItems[index].quantity,
                        );
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, node, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: node,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Search by name',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            onTap: () {
                              _loadAllItems();
                              node.requestFocus();
                            },
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Material(
                        elevation: 4.0,
                        child: SizedBox(
                          height: 200,
                          child: _isLoadingItems
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final item = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                      title: Text(
                                        '${item.itemCode} - ${item.itemName.capitalize()} - ₹${item.itemAmount}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      onTap: () => onSelected(item),
                                    );
                                  },
                                ),
                        ),
                      );
                    },
                  )
                : TextFormField(
                    controller: itemNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      setState(() {
                        orderItems[index] = OrderItem(
                          itemCode: item.itemCode,
                          itemName: value,
                          itemAmount: item.itemAmount,
                          itemStatus: item.itemStatus,
                          quantity: item.quantity,
                        );
                      });
                    },
                  ),
          ),

          // Compact Quantity Control
          // Compact Quantity Control
          SizedBox(
            width: 120, // Reduced width since we're removing spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrease button - with negative margin to pull it closer
                Transform.translate(
                  offset: const Offset(4, 0), // Pulls button 4px to the left
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (item.quantity == 1) {
                        updateQuantity(0.5);
                      } else if (item.quantity > 1) {
                        updateQuantity(item.quantity - 1);
                      } else {
                        updateQuantity(item.quantity - 0.25);
                      }
                    },
                  ),
                ),

                // Quantity input field with reduced padding
                SizedBox(
                  width: 40, // Slightly wider than content
                  height: 35,
                  child: TextFormField(
                    controller: quantityController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.zero, // Remove all padding
                      isDense: true, // Makes the field more compact
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      final newQty = double.tryParse(value) ?? 1.0;
                      if (newQty <= 0) {
                        setState(() => orderItems.removeAt(index));
                      } else {
                        updateQuantity(newQty);
                      }
                    },
                  ),
                ),

                // Increase button - with negative margin to pull it closer
                Transform.translate(
                  offset: const Offset(-4, 0), // Pulls button 4px to the right
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (item.quantity < 1) {
                        updateQuantity(item.quantity + 0.25);
                      } else {
                        updateQuantity(item.quantity + 1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Item Amount (read-only)
          SizedBox(
            width: 75,
            height: 40,
            child: TextFormField(
              controller: TextEditingController(
                text: item.itemAmount > 0
                    ? '₹${item.itemAmount.toStringAsFixed(2)}'
                    : '₹0.00',
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              readOnly: true,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => orderItems.removeAt(index)),
            ),
          ),
        ],
      ),
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
              'Make Order - ${_getDisplayName(supplierUsername ?? 'Supplier')}',
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
                onDistributePressed: () {
                  if (_quantityController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter member count first'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    _showMemberDistributionDialog();
                  }
                },
                onTableAllocatePressed: _handleTableAllocation,
              ),

              // Table Allocation Section
              if (_showTableAllocation) ...[
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

              // Order Items Section with Horizontal Scroll
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
                                          // ✅ COMMON HEADING ROW
                                          // In your build method, replace the header row with this:
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
                                                SizedBox(width: 8),
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
                                                SizedBox(width: 6),
                                                SizedBox(
                                                  width: 80,
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
                                                SizedBox(width: 4),
                                                SizedBox(
                                                  width: 25,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => setState(
                                                      () => orderItems.insert(
                                                        0,
                                                        OrderItem.empty(),
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

                                          // ✅ ITEM ROWS
                                          for (
                                            int i = 0;
                                            i < orderItems.length;
                                            i++
                                          )
                                            _buildOrderItemRow(
                                              i,
                                              orderItems[i],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),
                              // Replace the bottom buttons row with just the Submit Order button:
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

extension OrderItemExtension on OrderItem {
  static OrderItem empty() => OrderItem(
    itemCode: '',
    itemName: '',
    itemAmount: 0.0,
    itemStatus: true,
    quantity: 1,
  );
}
