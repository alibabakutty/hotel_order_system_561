import 'package:flutter/material.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/order_item_data.dart';

class OrderItemRow extends StatefulWidget {
  final int index;
  final OrderItem item;
  final List<ItemMasterData> allItems;
  final bool isLoadingItems;
  final Function(int) onRemove;
  final Function(int, OrderItem) onUpdate;
  final VoidCallback onItemSelected;
  final VoidCallback onAddNewRow;

  const OrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.allItems,
    required this.isLoadingItems,
    required this.onRemove,
    required this.onUpdate,
    required this.onItemSelected,
    required this.onAddNewRow,
  });

  @override
  State<OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<OrderItemRow> {
  late FocusNode focusNode;
  late TextEditingController quantityController;
  late TextEditingController netAmountController;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    quantityController = TextEditingController(
      text: widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(2),
    );
    netAmountController = TextEditingController(
      text:
          '₹${(widget.item.itemRateAmount * widget.item.quantity).toStringAsFixed(2)}',
    );

    // Add listener to quantity controller
    quantityController.addListener(_updateAmount);
  }

  @override
  void dispose() {
    quantityController.removeListener(_updateAmount);
    quantityController.dispose();
    netAmountController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final rate = widget.item.itemRateAmount;
    final amount = quantity * rate;

    // Update amount display
    netAmountController.text = '₹${amount.toStringAsFixed(2)}';

    // Update parent widget with new quantity
    widget.onUpdate(
      widget.index,
      OrderItem(
        itemCode: widget.item.itemCode,
        itemName: widget.item.itemName,
        itemRateAmount: widget.item.itemRateAmount,
        quantity: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First Row - S.No and Product Name
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          width: 1000,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // S.No
              SizedBox(
                width: 40,
                height: 32,
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Product Name
              SizedBox(
                width: 300,
                height: 32,
                child: widget.item.itemCode.isEmpty
                    ? _buildItemSearchField(focusNode)
                    : TextFormField(
                        controller: TextEditingController(
                          text: widget.item.itemName,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          widget.onUpdate(
                            widget.index,
                            OrderItem(
                              itemCode: widget.item.itemCode,
                              itemName: value,
                              itemRateAmount: widget.item.itemRateAmount,
                              quantity: widget.item.quantity,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Second Row - Qty, Rate, Amount, Delete
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          width: 1000,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 155),
              // Qty
              SizedBox(
                width: 40,
                height: 32,
                child: TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _updateAmount(),
                ),
              ),
              const SizedBox(width: 5),
              // Rate
              SizedBox(
                width: 70,
                height: 32,
                child: TextFormField(
                  controller: TextEditingController(
                    text: widget.item.itemRateAmount > 0
                        ? '₹${widget.item.itemRateAmount.toStringAsFixed(2)}'
                        : '₹0.00',
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  readOnly: true,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Amount
              SizedBox(
                width: 70,
                height: 32,
                child: TextFormField(
                  controller: netAmountController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  readOnly: true,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Delete button
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.green, size: 16),
                  padding: EdgeInsets.zero,
                  onPressed: widget.onAddNewRow,
                ),
              ),
              const SizedBox(width: 2),
              // Delete button
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onRemove(widget.index),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemSearchField(FocusNode focusNode) {
    return RawAutocomplete<ItemMasterData>(
      focusNode: focusNode,
      textEditingController: TextEditingController(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (widget.isLoadingItems) {
          return const Iterable<ItemMasterData>.empty();
        }

        if (textEditingValue.text.isEmpty) {
          return widget.allItems;
        }

        return widget.allItems.where((item) {
          final searchTerm = textEditingValue.text.toLowerCase();
          final matchesCode = item.itemCode.toString().toLowerCase().contains(
            searchTerm,
          );
          final matchesName = item.itemName.toLowerCase().contains(searchTerm);
          return matchesCode || matchesName;
        });
      },
      onSelected: (ItemMasterData selection) {
        final initialQuantity = 1.0;
        final initialAmount = selection.itemRateAmount * initialQuantity;

        // Update quantity controller
        quantityController.text = initialQuantity.toStringAsFixed(0);
        // Update amount controller
        netAmountController.text = '₹${initialAmount.toStringAsFixed(2)}';

        widget.onUpdate(
          widget.index,
          OrderItem(
            itemCode: selection.itemCode.toString(),
            itemName: selection.itemName.capitalize(),
            itemRateAmount: selection.itemRateAmount,
            quantity: initialQuantity,
          ),
        );

        widget.onItemSelected();
      },

      fieldViewBuilder: (context, controller, node, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: node,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Search by code/name',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          onTap: () => node.requestFocus(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: SizedBox(
            height: 180,
            child: widget.isLoadingItems
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          '${item.itemCode} - ${item.itemName.capitalize()} - ₹${item.itemRateAmount}',
                          style: const TextStyle(fontSize: 13),
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
