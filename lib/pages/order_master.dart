import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';
import 'package:go_router/go_router.dart';

class OrderItem {
  String itemCode;
  String itemName;
  double itemAmount;
  bool itemStatus;
  int quantity;
  TextEditingController codeController;
  TextEditingController nameController;
  TextEditingController amountController;
  TextEditingController qtyController;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.itemAmount,
    required this.itemStatus,
    required this.quantity,
  }) : codeController = TextEditingController(text: itemCode),
       nameController = TextEditingController(text: itemName),
       amountController = TextEditingController(text: itemAmount.toString()),
       qtyController = TextEditingController(text: quantity.toString());

  void dispose() {
    codeController.dispose();
    nameController.dispose();
    amountController.dispose();
    qtyController.dispose();
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

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _serialNoController = TextEditingController();
  final _tableNoController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _kidsController = TextEditingController();

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

      List<Map<String, dynamic>> items = [];
      for (var item in orderItems) {
        if (item.itemCode.isNotEmpty && item.itemName.isNotEmpty) {
          items.add({
            'itemCode': item.itemCode,
            'itemName': item.itemName,
            'quantity': item.quantity,
            'status': item.itemStatus ? 'Available' : 'Not Available',
          });
        }
      }

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

  @override
  void dispose() {
    for (var item in orderItems) {
      item.dispose();
    }
    _serialNoController.dispose();
    _tableNoController.dispose();
    _supplierNameController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _kidsController.dispose();
    super.dispose();
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
              // Member Input Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guest Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Total Members',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Numbers only';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_quantityController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter member count',
                                      ),
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
                              icon: const Icon(Icons.group_add),
                              label: const Text('Distribute Members'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Order Items Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) => Colors.grey[100],
                              ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Item Code',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Item Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: orderItems.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: item.codeController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          item.itemCode = value,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: TextFormField(
                                      controller: item.nameController,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          item.itemName = value,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: item.qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        item.quantity =
                                            int.tryParse(value) ?? 0;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: item.amountController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        prefixText: '\$',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        item.itemAmount =
                                            double.tryParse(value) ?? 0.0;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.itemStatus
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.itemStatus
                                          ? 'Available'
                                          : 'Unavailable',
                                      style: TextStyle(
                                        color: item.itemStatus
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        color: Colors.grey,
                                        onPressed: () {
                                          setState(() {
                                            item.dispose();
                                            orderItems.remove(item);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
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
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _submitOrder,
                            icon: const Icon(Icons.send),
                            label: const Text('Submit Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
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
}
