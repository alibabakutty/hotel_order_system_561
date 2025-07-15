import 'package:flutter/material.dart';
import 'package:food_order_system/models/table_master_data.dart';
import 'package:food_order_system/service/firebase_service.dart';

class AllocateTableSection extends StatefulWidget {
  final TextEditingController quantityController;
  final List<TableMasterData> selectedTables;
  final Function(List<TableMasterData>) onTablesSelected;

  const AllocateTableSection({
    super.key,
    required this.quantityController,
    required this.selectedTables,
    required this.onTablesSelected,
  });

  @override
  State<AllocateTableSection> createState() => _AllocateTableSectionState();
}

class _AllocateTableSectionState extends State<AllocateTableSection> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  List<TableMasterData> _availableTables = [];
  bool _isLoadingTables = false;
  int _totalCapacity = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
    widget.quantityController.addListener(_updateTotalMembers);
  }

  @override
  void dispose() {
    widget.quantityController.removeListener(_updateTotalMembers);
    super.dispose();
  }

  void _updateTotalMembers() {
    setState(() {
      // Recalculate required capacity when total members changes
    });
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _isLoadingTables = true;
    });
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
      setState(() {
        _isLoadingTables = false;
      });
    }
  }

  void _showTableSelectionDialog(BuildContext context) {
    final totalMembers = int.tryParse(widget.quantityController.text) ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Tables'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Members: $totalMembers'),
                  Text(
                    'Selected Capacity: $_totalCapacity/${totalMembers > 0 ? totalMembers : '?'}',
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingTables)
                    const Center(child: CircularProgressIndicator())
                  else if (_availableTables.isEmpty)
                    const Text('No available tables')
                  else
                    SizedBox(
                      height: 300,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: _availableTables.length,
                        itemBuilder: (context, index) {
                          final table = _availableTables[index];
                          final isSelected = widget.selectedTables.any(
                            (t) => t.tableNumber == table.tableNumber,
                          );

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  widget.selectedTables.add(table);
                                  _totalCapacity += table.tableCapacity;
                                } else {
                                  widget.selectedTables.removeWhere(
                                    (t) => t.tableNumber == table.tableNumber,
                                  );
                                  _totalCapacity -= table.tableCapacity;
                                }
                              });
                            },
                            title: Text('Table ${table.tableNumber}'),
                            subtitle: Text('Capacity: ${table.tableCapacity}'),
                            secondary: table.tableAvailability
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.close, color: Colors.red),
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _totalCapacity >= totalMembers
                      ? () {
                          widget.onTablesSelected(widget.selectedTables);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Confirm Selection'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Table Allocation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Total Members input field
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: widget.quantityController,
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
                  const SizedBox(width: 8),

                  // Selected tables info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.selectedTables.isNotEmpty) ...[
                          Text(
                            'Selected Tables: ${widget.selectedTables.map((t) => t.tableNumber).join(', ')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Total Capacity: ${widget.selectedTables.fold(0, (sum, table) => sum + table.tableCapacity)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ] else
                          const Text(
                            'No tables selected',
                            style: TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _showTableSelectionDialog(context);
                    }
                  },
                  icon: const Icon(Icons.table_restaurant),
                  label: const Text('Select Tables'),
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
      ),
    );
  }
}
