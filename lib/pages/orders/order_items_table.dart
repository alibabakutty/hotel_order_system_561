import 'package:flutter/material.dart';
import 'package:food_order_system/models/order_item_data.dart';
import 'package:food_order_system/models/item_master_data.dart';

class OrderItemsTable extends StatefulWidget {
  final List<OrderItem> orderItems;
  final Function(int index) onDeleteItem;
  final Function() onAddItem;
  final Function() onSubmitOrder;
  final List<ItemMasterData> allItems;
  final bool isLoadingItems;

  const OrderItemsTable({
    super.key,
    required this.orderItems,
    required this.onDeleteItem,
    required this.onAddItem,
    required this.onSubmitOrder,
    required this.allItems,
    required this.isLoadingItems,
  });

  @override
  State<OrderItemsTable> createState() => _OrderItemsTableState();
}

class _OrderItemsTableState extends State<OrderItemsTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  late List<TextEditingController> qtyControllers;
  late List<FocusNode> itemCodeFocusNodes;

  @override
  void initState() {
    super.initState();
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
    _disposeControllers();
    qtyControllers = [];
    itemCodeFocusNodes = [];

    for (var item in widget.orderItems) {
      qtyControllers.add(TextEditingController(text: item.quantity.toString()));
      itemCodeFocusNodes.add(FocusNode());
    }
  }

  void _disposeControllers() {
    for (var controller in qtyControllers) {
      controller.dispose();
    }
    for (var focusNode in itemCodeFocusNodes) {
      focusNode.dispose();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  Widget _buildItemCodeField(int index, OrderItem item) {
    return RawAutocomplete<ItemMasterData>(
      focusNode: itemCodeFocusNodes[index],
      textEditingController: TextEditingController(text: item.itemCode),
      optionsBuilder: (TextEditingValue textEditingValue) {
        return widget.isLoadingItems
            ? const Iterable<ItemMasterData>.empty()
            : widget.allItems.where(
                (item) =>
                    item.itemCode.toString().contains(textEditingValue.text) ||
                    item.itemName.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
              );
      },
      onSelected: (ItemMasterData selection) {
        setState(() {
          widget.orderItems[index] = OrderItem(
            itemCode: selection.itemCode.toString(),
            itemName: selection.itemName,
            itemAmount: selection.itemAmount,
            itemStatus: selection.itemStatus,
            quantity: widget.orderItems[index].quantity,
          );
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search by code/name',
            hintStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: SizedBox(
            height: 200,
            child: widget.isLoadingItems
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          '${item.itemCode} - ${item.itemName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '₹${item.itemAmount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => onSelected(item),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double codeWidth = 200;
    const double nameWidth = 200;
    const double qtyWidth = 100;
    const double amountWidth = 100;
    const double statusWidth = 100;
    const double actionWidth = 80;

    final totalWidth =
        codeWidth +
        nameWidth +
        qtyWidth +
        amountWidth +
        statusWidth +
        actionWidth;

    return Column(
      children: [
        // Header Row
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            child: SizedBox(
              width: totalWidth,
              child: Row(
                children: [
                  SizedBox(
                    width: codeWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Item code/name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: nameWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Item name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: qtyWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: amountWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Table Content
        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    children: widget.orderItems.map((item) {
                      final index = widget.orderItems.indexOf(item);
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Item Code with Autocomplete
                            SizedBox(
                              width: codeWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildItemCodeField(index, item),
                              ),
                            ),
                            // Item Name
                            SizedBox(
                              width: nameWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  item.itemName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Quantity
                            SizedBox(
                              width: qtyWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: qtyControllers[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    widget.orderItems[index] = OrderItem(
                                      itemCode: item.itemCode,
                                      itemName: item.itemName,
                                      itemAmount: item.itemAmount,
                                      itemStatus: item.itemStatus,
                                      quantity: item.quantity,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Amount
                            SizedBox(
                              width: amountWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '₹${item.itemAmount.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Status
                            SizedBox(
                              width: statusWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: item.itemStatus
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            // Action
                            SizedBox(
                              width: actionWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 24),
                                  color: Colors.red,
                                  onPressed: () => widget.onDeleteItem(index),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Buttons at the bottom
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: widget.onAddItem,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onSubmitOrder,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Submit order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
