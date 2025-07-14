import 'package:flutter/material.dart';
import 'package:food_order_system/authentication/auth_models.dart';
import 'package:food_order_system/authentication/auth_service.dart';
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

  // Section expansion states
  bool _firstOrderExpanded = true;
  bool _secondOrderExpanded = false;

  // Order items list
  final List<Map<String, dynamic>> _firstOrderItems = [];
  final List<Map<String, dynamic>> _secondOrderItems = [];

  // controllers
  final _firstOrderController = TextEditingController();
  final _secondOrderController = TextEditingController();

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

  // Controllers
  // final _formKey = GlobalKey<FormState>();
  final _serialNoController = TextEditingController();
  final _tableNoController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _kidsController = TextEditingController();

  @override
  void dispose() {
    _serialNoController.dispose();
    _tableNoController.dispose();
    _supplierNameController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _kidsController.dispose();
    _firstOrderController.dispose();
    _secondOrderController.dispose();
    super.dispose();
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
            // int kids = int.tryParse(_kidsController.text) ?? 0;

            // Track which fields have been manually entered
            if (changedField == 'male' && _maleController.text.isNotEmpty) {
              maleEntered = true;
            }
            if (changedField == 'female' && _femaleController.text.isNotEmpty) {
              femaleEntered = true;
            }

            // Auto-balance logic
            if (maleEntered && !femaleEntered) {
              // Only male entered - don't adjust anything yet
              return;
            } else if (maleEntered && femaleEntered) {
              // Both male and female entered - calculate kids
              int calculatedKids = totalMembers - male - female;
              if (calculatedKids >= 0) {
                _kidsController.text = calculatedKids.toString();
              } else {
                // If over total, reduce female to make room
                _femaleController.text = (female + calculatedKids).toString();
                _kidsController.text = '0';
              }
            } else if (!maleEntered && femaleEntered) {
              // Only female entered - don't adjust anything yet
              return;
            }
          }

          return AlertDialog(
            title: Text('Distribute $totalMembers Members'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // Male Input
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

                // Female Input
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

                // Kids Input (read-only)
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

  void _addFirstOrderItem() {
    if (_firstOrderController.text.isNotEmpty) {
      setState(() {
        _firstOrderItems.add({
          'name': _firstOrderController.text,
          'quantity': 1,
        });
        _firstOrderController.clear();
      });
    }
  }

  void _addSecondOrderItem() {
    if (_secondOrderController.text.isNotEmpty) {
      setState(() {
        _secondOrderItems.add({
          'name': _secondOrderController.text,
          'quantity': 1,
        });
        _secondOrderController.clear();
      });
    }
  }

  void _toggleFirstOrder() {
    setState(() {
      _firstOrderExpanded = !_firstOrderExpanded;
      if (_firstOrderExpanded) {
        _secondOrderExpanded = false;
      }
    });
  }

  void _toggleSecondOrder() {
    setState(() {
      _secondOrderExpanded = !_secondOrderExpanded;
      if (_secondOrderExpanded) {
        _firstOrderExpanded = false;
      }
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Member count and check-in section
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Members',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter count';
                      if (int.tryParse(value) == null) return 'Numbers only';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
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
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Guest Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // First Order Section
            Card(
              child: ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.zero,
                expansionCallback: (int index, bool isExpanded) {
                  _toggleFirstOrder();
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: const Text('First Part of Order'),
                        trailing: Icon(
                          _firstOrderExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _firstOrderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Item Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addFirstOrderItem,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_firstOrderItems.isNotEmpty)
                            Table(
                              border: TableBorder.all(),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Colors.grey),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Action',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ..._firstOrderItems.map((item) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(item['name']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item['quantity'].toString(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              _firstOrderItems.remove(item);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                    isExpanded: _firstOrderExpanded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Second Order Section
            Card(
              child: ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.zero,
                expansionCallback: (int index, bool isExpanded) {
                  _toggleSecondOrder();
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: const Text('Second Part of Order'),
                        trailing: Icon(
                          _secondOrderExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _secondOrderController,
                                  decoration: const InputDecoration(
                                    labelText: 'Item Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addSecondOrderItem,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_secondOrderItems.isNotEmpty)
                            Table(
                              border: TableBorder.all(),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Colors.grey),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Action',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ..._secondOrderItems.map((item) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(item['name']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item['quantity'].toString(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              _secondOrderItems.remove(item);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                    isExpanded: _secondOrderExpanded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                // Submit both orders
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order submitted with ${_firstOrderItems.length + _secondOrderItems.length} items',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Submit Complete Order'),
            ),
          ],
        ),
      ),
    );
  }
}
