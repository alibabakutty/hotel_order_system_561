import 'package:flutter/material.dart';

class AllocateTableSection extends StatefulWidget {
  final TextEditingController tableNoController;
  final TextEditingController tableCapacityController;
  final Function() onTableAllocated;

  const AllocateTableSection({
    super.key,
    required this.tableNoController,
    required this.tableCapacityController,
    required this.onTableAllocated,
  });

  @override
  State<AllocateTableSection> createState() => _AllocateTableSectionState();
}

class _AllocateTableSectionState extends State<AllocateTableSection> {
  final _formKey = GlobalKey<FormState>();

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
                  // Table Number input field
                  Expanded(
                    child: TextFormField(
                      controller: widget.tableNoController,
                      decoration: const InputDecoration(
                        labelText: 'Table Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.table_restaurant),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Table Capacity input field
                  Expanded(
                    child: TextFormField(
                      controller: widget.tableCapacityController,
                      decoration: const InputDecoration(
                        labelText: 'Table Capacity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_outline),
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
                  
                  // Allocate Table button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onTableAllocated();
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Allocate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
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