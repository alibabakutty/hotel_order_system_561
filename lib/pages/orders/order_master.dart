import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';
import 'package:food_order_system/models/order_item_data.dart';
import 'package:food_order_system/pages/orders/allocate_table_section.dart';
import 'package:food_order_system/pages/orders/guest_info_section.dart';
import 'package:food_order_system/pages/orders/order_items_table.dart';
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
  List<OrderItem> orderItems = [
    OrderItem(
      itemCode: '',
      itemName: '',
      itemAmount: 0.0,
      itemStatus: true,
      quantity: 1,
    ),
  ];

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _serialNoController = TextEditingController();
  final _tableNoController = TextEditingController();
  final _tableCapacityController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _kidsController = TextEditingController();

  bool _showTableAllocation = false;

  @override
  void initState() {
    super.initState();
    _fetchSupplierData();
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
        _supplierNameController.text = supplierUsername!;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading supplier data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/supplier_login');
      }
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

  String _getDisplayName(String name) {
    const maxLength = 12;
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  void _showMemberDistributionDialog() {
    int totalMembers = int.tryParse(_quantityController.text) ?? 0;
    bool maleEntered = false;
    bool femaleEntered = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateCounts({String? changedField}) {
            int male = int.tryParse(_maleController.text) ?? 0;
            int female = int.tryParse(_femaleController.text) ?? 0;

            if (changedField == 'male' && _maleController.text.isNotEmpty) {
              maleEntered = true;
            }
            if (changedField == 'female' && _femaleController.text.isNotEmpty) {
              femaleEntered = true;
            }

            if (maleEntered && !femaleEntered) {
              return;
            } else if (maleEntered && femaleEntered) {
              int calculatedKids = totalMembers - male - female;
              if (calculatedKids >= 0) {
                _kidsController.text = calculatedKids.toString();
              } else {
                _femaleController.text = (female + calculatedKids).toString();
                _kidsController.text = '0';
              }
            } else if (!maleEntered && femaleEntered) {
              return;
            }
          }

          return AlertDialog(
            title: Text('Distribute $totalMembers Members'),
            content: Column(
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
                  onChanged: (value) => updateCounts(changedField: 'male'),
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
                  onChanged: (value) => updateCounts(changedField: 'female'),
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
                  keyboardType: TextInputType.number,
                ),
              ],
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
                      SnackBar(
                        content: Text('Total must equal $totalMembers members'),
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
          (orderItems.length == 1 &&
              orderItems[0].itemCode.isEmpty &&
              orderItems[0].itemName.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one order item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> items = orderItems
          .where((item) => item.itemCode.isNotEmpty && item.itemName.isNotEmpty)
          .map((item) => item.toMap())
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order submitted with ${items.length} items'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        orderItems = [
          OrderItem(
            itemCode: '',
            itemName: '',
            itemAmount: 0.00,
            itemStatus: true,
            quantity: 1,
          ),
        ];
      });
    }
  }

  void _handleTableAllocation() {
    setState(() {
      _showTableAllocation = !_showTableAllocation;
    });
  }

  void _confirmTableAllocation() {
    if (_tableNoController.text.isNotEmpty &&
        _tableCapacityController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${_tableNoController.text} allocated (Capacity: ${_tableCapacityController.text})',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _showTableAllocation = false;
      });
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
                  builder: (context, snapshot) => Text(
                    '${TimeOfDay.now().format(context)}  ',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Make Order - ', style: TextStyle(fontSize: 16)),
                Text(
                  _getDisplayName(supplierUsername ?? 'Supplier'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logged in as ${supplierUsername ?? 'Supplier'}',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GuestInfoSection(
                quantityController: _quantityController,
                maleController: _maleController,
                femaleController: _femaleController,
                kidsController: _kidsController,
                onDistributePressed: () {
                  if (_quantityController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter member count'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    _maleController.clear();
                    _femaleController.clear();
                    _kidsController.clear();
                    _showMemberDistributionDialog();
                  }
                },
                onTableAllocatePressed: _handleTableAllocation,
              ),
              if (_showTableAllocation) ...[
                const SizedBox(height: 16),
                AllocateTableSection(
                  tableNoController: _tableNoController,
                  tableCapacityController: _tableCapacityController,
                  onTableAllocated: _confirmTableAllocation,
                ),
              ],
              const SizedBox(height: 24),
              OrderItemsTable(
                orderItems: orderItems,
                onDeleteItem: (index) {
                  setState(() {
                    orderItems.removeAt(index);
                  });
                },
                onAddItem: () {
                  setState(() {
                    orderItems.add(
                      OrderItem(
                        itemCode: '',
                        itemName: '',
                        itemAmount: 0.0,
                        itemStatus: true,
                        quantity: 1,
                      ),
                    );
                  });
                },
                onSubmitOrder: _submitOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serialNoController.dispose();
    _tableNoController.dispose();
    _tableCapacityController.dispose();
    _supplierNameController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _kidsController.dispose();
    super.dispose();
  }
}
