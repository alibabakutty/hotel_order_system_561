import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TableMaster extends StatefulWidget {
  const TableMaster({super.key});

  @override
  State<TableMaster> createState() => _TableMasterState();
}

class _TableMasterState extends State<TableMaster> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _tableSizeController = TextEditingController();
  String? _selectedTableType;

  // Available table types
  final List<String> _tableTypes = ['Small', 'Medium', 'Large'];

  @override
  void dispose() {
    _tableNumberController.dispose();
    _tableSizeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${_tableNumberController.text} added successfully',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Here you would typically save to database or API
      print('Table Number: ${_tableNumberController.text}');
      print('Table Size: ${_tableSizeController.text}');
      print('Table Type: $_selectedTableType');

      // Clear the form after submission
      _formKey.currentState!.reset();
      setState(() => _selectedTableType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Master'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'table'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Add New Table',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Table Number Field
              TextFormField(
                controller: _tableNumberController,
                decoration: InputDecoration(
                  labelText: 'Table Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.table_restaurant),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter table number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Table Size Field
              TextFormField(
                controller: _tableSizeController,
                decoration: InputDecoration(
                  labelText: 'Table Size (Capacity)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.people),
                  suffixText: 'persons',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter table capacity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Table Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedTableType,
                decoration: InputDecoration(
                  labelText: 'Table Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _tableTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTableType = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select table type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save Table',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
