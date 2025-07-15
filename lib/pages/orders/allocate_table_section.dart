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
            return AlertDialog(
              title: const Text('Select Table'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingTables)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableTables.isEmpty)
                      const Text('No available tables')
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: _availableTables.length,
                          itemBuilder: (context, index) {
                            final table = _availableTables[index];
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
                              title: Text('Table ${table.tableNumber}'),
                              subtitle: Text(
                                'Capacity: ${table.tableCapacity}',
                              ),
                              secondary: Icon(
                                table.tableAvailability
                                    ? Icons.check
                                    : Icons.close,
                                color: table.tableAvailability
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          },
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
                  onPressed: widget.selectedTable != null
                      ? () => Navigator.pop(context)
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Table Allocation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.selectedTable != null) ...[
              ListTile(
                leading: const Icon(
                  Icons.table_restaurant,
                  color: Colors.green,
                ),
                title: Text('Table ${widget.selectedTable!.tableNumber}'),
                subtitle: Text(
                  'Capacity: ${widget.selectedTable!.tableCapacity}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => widget.onTableSelected(null),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showTableSelectionDialog(context), // Wrap in function
                icon: const Icon(Icons.table_restaurant),
                label: Text(
                  widget.selectedTable == null
                      ? 'Select Table'
                      : 'Change Table',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
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
