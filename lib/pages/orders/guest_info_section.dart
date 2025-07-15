import 'package:flutter/material.dart';

class GuestInfoSection extends StatefulWidget {
  final TextEditingController quantityController;
  final TextEditingController maleController;
  final TextEditingController femaleController;
  final TextEditingController kidsController;
  final Function() onDistributePressed;
  final Function() onTableAllocatePressed;

  const GuestInfoSection({
    super.key,
    required this.quantityController,
    required this.maleController,
    required this.femaleController,
    required this.kidsController,
    required this.onDistributePressed,
    required this.onTableAllocatePressed,
  });

  @override
  State<GuestInfoSection> createState() => _GuestInfoSectionState();
}

class _GuestInfoSectionState extends State<GuestInfoSection> {
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
              'Guest Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Table Allocate button (first)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onTableAllocatePressed,
                    icon: const Icon(Icons.table_restaurant),
                    label: const Text('Allocate Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Total Members input field (middle)
                Expanded(
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

                // Guest Checkin button (last)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onDistributePressed,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
