import 'package:flutter/material.dart';
import 'package:food_order_system/models/table_master_data.dart';
import 'package:food_order_system/service/firebase_service.dart';

class AllocateTableSection extends StatefulWidget {
  final TableMasterData? selectedTable;
  final Function(TableMasterData?) onTableSelected;
  final double? width;
  final double? height;

  const AllocateTableSection({
    super.key,
    required this.selectedTable,
    required this.onTableSelected,
    this.width,
    this.height,
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
              insetPadding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.width ?? 280,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                      child: Row(
                        children: [
                          Text(
                            'SELECT TABLE',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: _isLoadingTables
                          ? const Center(child: CircularProgressIndicator())
                          : _availableTables.isEmpty
                          ? const Center(child: Text('No tables available'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _availableTables.length,
                              itemBuilder: (context, index) {
                                final table = _availableTables[index];
                                final isSelected =
                                    widget.selectedTable?.tableNumber ==
                                    table.tableNumber;

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  leading: Radio<TableMasterData>(
                                    value: table,
                                    groupValue: isSelected
                                        ? widget.selectedTable
                                        : null,
                                    onChanged: (t) {
                                      widget.onTableSelected(t);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  title: Text(
                                    'Table ${table.tableNumber}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Text(
                                    '${table.tableCapacity}p',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    widget.onTableSelected(table);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),

                    // Footer
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'),
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
    return SizedBox(
      width: 370,
      height: widget.height ?? 80, // Default height if not specified
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedTable == null)
                ElevatedButton.icon(
                  onPressed: () => _showTableSelectionDialog(context),
                  icon: const Icon(Icons.table_restaurant, size: 16),
                  label: const Text('SELECT TABLE'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                ),

              if (widget.selectedTable != null)
                Row(
                  children: [
                    const Icon(
                      Icons.table_restaurant,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${widget.selectedTable!.tableNumber}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${widget.selectedTable!.tableCapacity} persons',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showTableSelectionDialog(context),
                      tooltip: 'Change table',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => widget.onTableSelected(null),
                      tooltip: 'Clear selection',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
