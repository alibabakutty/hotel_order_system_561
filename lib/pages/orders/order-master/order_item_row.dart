import 'package:flutter/material.dart';
import 'package:food_order_system/models/item_master_data.dart';
import 'package:food_order_system/models/order_item_data.dart';
import 'package:food_order_system/pages/cda_page.dart';

class OrderItemRow extends StatelessWidget {
  final int index;
  final OrderItem item;
  final List<ItemMasterData> allItems;
  final bool isLoadingItems;
  final Function(int) onRemove;
  final Function(int, OrderItem) onUpdate;

  const OrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.allItems,
    required this.isLoadingItems,
    required this.onRemove,
    required this.onUpdate,
  });

  void _updateQuantity(OrderItem item, double newQty) {
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
      onRemove(index);
      return;
    }

    onUpdate(
      index,
      OrderItem(
        itemCode: item.itemCode,
        itemName: item.itemName,
        itemAmount: item.itemAmount,
        itemStatus: item.itemStatus,
        quantity: newQty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemNameController = TextEditingController(text: item.itemName);
    final focusNode = FocusNode();
    final quantityController = TextEditingController(
      text: item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2),
    );

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
                      return isLoadingItems
                          ? const Iterable<ItemMasterData>.empty()
                          : allItems.where(
                              (item) => item.itemName.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                    },
                    onSelected: (ItemMasterData selection) {
                      onUpdate(
                        index,
                        OrderItem(
                          itemCode: selection.itemCode.toString(),
                          itemName: selection.itemName.capitalize(),
                          itemAmount: selection.itemAmount,
                          itemStatus: selection.itemStatus,
                          quantity: item.quantity,
                        ),
                      );
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
                            onTap: () => node.requestFocus(),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Material(
                        elevation: 4.0,
                        child: SizedBox(
                          height: 200,
                          child: isLoadingItems
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
                      fontSize: 11,
                    ),
                    onChanged: (value) {
                      onUpdate(
                        index,
                        OrderItem(
                          itemCode: item.itemCode,
                          itemName: value,
                          itemAmount: item.itemAmount,
                          itemStatus: item.itemStatus,
                          quantity: item.quantity,
                        ),
                      );
                    },
                  ),
          ),

          // Compact Quantity Control
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(4, 0),
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (item.quantity == 1) {
                        _updateQuantity(item, 0.5);
                      } else if (item.quantity > 1) {
                        _updateQuantity(item, item.quantity - 1);
                      } else {
                        _updateQuantity(item, item.quantity - 0.25);
                      }
                    },
                  ),
                ),

                SizedBox(
                  width: 40,
                  height: 35,
                  child: TextFormField(
                    controller: quantityController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      final newQty = double.tryParse(value) ?? 1.0;
                      if (newQty <= 0) {
                        onRemove(index);
                      } else {
                        _updateQuantity(item, newQty);
                      }
                    },
                  ),
                ),

                Transform.translate(
                  offset: const Offset(-4, 0),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (item.quantity < 1) {
                        _updateQuantity(item, item.quantity + 0.25);
                      } else {
                        _updateQuantity(item, item.quantity + 1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Item Amount (read-only)
          SizedBox(
            width: 70,
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
                fontSize: 11,
              ),
            ),
          ),

          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              padding: EdgeInsets.zero,
              onPressed: () => onRemove(index),
            ),
          ),
        ],
      ),
    );
  }
}
