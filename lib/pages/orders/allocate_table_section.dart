import 'package:flutter/material.dart';
import 'package:food_order_system/models/table_master_data.dart';
import 'package:food_order_system/service/firebase_service.dart';

class AllocateTableSection extends StatefulWidget {
  final TableMasterData? selectedTable;
  final Function(TableMasterData?) onTableSelected;

  const AllocateTableSection({
    super.key,
    required this.selectedTable,
    required this.onTableSelected,
  });

  @override
  State<AllocateTableSection> createState() => _AllocateTableSectionState();
}

class _AllocateTableSectionState extends State<AllocateTableSection> {
  final FirebaseService _firebaseService = FirebaseService();
  List<TableMasterData> _availableTables = [];
  bool _isLoadingTables = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

  Future<void> _loadAvailableTables() async {
    setState(() => _isLoadingTables = true);
    try {
      final tables = await _firebaseService.getAllTables();
      setState(() {
        _availableTables = tables
            .where((table) => table.tableAvailability)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading tables: $e');
    } finally {
      setState(() => _isLoadingTables = false);
    }
  }

  void _showTableSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Select Table',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_isLoadingTables)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      )
                    else if (_availableTables.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No available tables'),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _availableTables.map((table) {
                              final isSelected =
                                  widget.selectedTable?.tableNumber ==
                                  table.tableNumber;

                              return RadioListTile<TableMasterData>(
                                value: table,
                                groupValue: isSelected
                                    ? widget.selectedTable
                                    : null,
                                onChanged: (selectedTable) {
                                  setState(() {
                                    widget.onTableSelected(selectedTable);
                                  });
                                },
                                title: Text(
                                  'Table ${table.tableNumber}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Capacity: ${table.tableCapacity}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                secondary: Icon(
                                  table.tableAvailability
                                      ? Icons.check
                                      : Icons.close,
                                  size: 20,
                                  color: table.tableAvailability
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: widget.selectedTable != null
                                ? () => Navigator.pop(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('CONFIRM'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for reducing height
          children: [
            const Text(
              'Table Allocation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8), // Reduced spacing
            if (widget.selectedTable != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_restaurant,
                      color: Colors.green,
                      size: 24, // Slightly smaller icon
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Table ${widget.selectedTable!.tableNumber}'),
                          Text(
                            'Capacity: ${widget.selectedTable!.tableCapacity}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => widget.onTableSelected(null),
                      padding: EdgeInsets.zero, // Remove extra padding
                      constraints: const BoxConstraints(), // Remove constraints
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTableSelectionDialog(context),
                icon: const Icon(Icons.table_restaurant, size: 18),
                label: Text(
                  widget.selectedTable == null
                      ? 'Select Table'
                      : 'Change Table',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12, // Reduced padding
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
