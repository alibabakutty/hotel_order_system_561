import 'package:flutter/material.dart';
import 'package:food_order_system/models/order_item_data.dart';

class OrderItemsTable extends StatefulWidget {
  final List<OrderItem> orderItems;
  final Function(int index) onDeleteItem;
  final Function() onAddItem;
  final Function() onSubmitOrder;

  const OrderItemsTable({
    super.key,
    required this.orderItems,
    required this.onDeleteItem,
    required this.onAddItem,
    required this.onSubmitOrder,
  });

  @override
  State<OrderItemsTable> createState() => _OrderItemsTableState();
}

class _OrderItemsTableState extends State<OrderItemsTable> {
  late List<TextEditingController> codeControllers;
  late List<TextEditingController> nameControllers;
  late List<TextEditingController> amountControllers;
  late List<TextEditingController> qtyControllers;

  @override
  void initState() {
    super.initState();
    // Initialize controllers when widget is first created
    codeControllers = [];
    nameControllers = [];
    amountControllers = [];
    qtyControllers = [];
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant OrderItemsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderItems.length != widget.orderItems.length) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Dispose old controllers if they exist
    _disposeControllers();

    // Create new controllers for each order item
    for (var item in widget.orderItems) {
      codeControllers.add(TextEditingController(text: item.itemCode));
      nameControllers.add(TextEditingController(text: item.itemName));
      amountControllers.add(
        TextEditingController(text: item.itemAmount.toString()),
      );
      qtyControllers.add(TextEditingController(text: item.quantity.toString()));
    }
  }

  void _disposeControllers() {
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in amountControllers) {
      controller.dispose();
    }
    for (var controller in qtyControllers) {
      controller.dispose();
    }

    // Clear the lists
    codeControllers.clear();
    nameControllers.clear();
    amountControllers.clear();
    qtyControllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table with vertical and horizontal scrolling
            SizedBox(
              height: 400, // Fixed height with scrolling
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) => Colors.grey[100],
                    ),
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            'Item Code',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Text(
                            'Item Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            'Amount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text(
                            'Remove',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(widget.orderItems.length, (
                      index,
                    ) {
                      final item = widget.orderItems[index];
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: codeControllers[index],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) => item.itemCode = value,
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
                                controller: nameControllers[index],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) => item.itemName = value,
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
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          item.quantity--;
                                          qtyControllers[index].text = item
                                              .quantity
                                              .toString();
                                        }
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: qtyControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        item.quantity =
                                            int.tryParse(value) ?? 1;
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
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        item.quantity++;
                                        qtyControllers[index].text = item
                                            .quantity
                                            .toString();
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: amountControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixText: '\₹',
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
                                item.itemStatus ? 'Available' : 'Unavailable',
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
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.grey,
                                  onPressed: () => widget.onDeleteItem(index),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onSubmitOrder,
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
    );
  }
}
