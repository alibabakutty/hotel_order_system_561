import 'package:flutter/material.dart';

class GuestInfoSection extends StatefulWidget {
  final TextEditingController quantityController;
  final TextEditingController maleController;
  final TextEditingController femaleController;
  final TextEditingController kidsController;
  final Function() onDistributePressed;
  final Function() onTableAllocatePressed;
  final String? selectedTable; // Add selected table parameter
  final int? totalMembers; // Add total members parameter

  const GuestInfoSection({
    super.key,
    required this.quantityController,
    required this.maleController,
    required this.femaleController,
    required this.kidsController,
    required this.onDistributePressed,
    required this.onTableAllocatePressed,
    this.selectedTable,
    this.totalMembers,
  });

  @override
  State<GuestInfoSection> createState() => _GuestInfoSectionState();
}

class _GuestInfoSectionState extends State<GuestInfoSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Table info badge if table is selected
                  if (widget.selectedTable != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Table: ${widget.selectedTable}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (widget.selectedTable != null) const SizedBox(width: 8),

                  // Members count badge if members count exists
                  if (widget.totalMembers != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Members: ${widget.totalMembers}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  Text(
                    'GUEST INFO',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildIconButton(
                    icon: Icons.table_restaurant,
                    color: Colors.green.shade700,
                    onPressed: widget.onTableAllocatePressed,
                  ),
                  const SizedBox(width: 6),
                  _buildNumberInput(),
                  const SizedBox(width: 6),
                  _buildIconButton(
                    icon: Icons.group_add,
                    color: Colors.orange.shade700,
                    onPressed: widget.onDistributePressed,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required Function() onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNumberInput() {
    return SizedBox(
      width: 60,
      height: 36,
      child: TextFormField(
        controller: widget.quantityController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
