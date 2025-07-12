import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin AdminDashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          onPressed: () {
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Hotel Order Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your hotel arrangements',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Item Master Card
            _buildMasterCard(
              context,
              title: 'Item Master',
              subtitle: 'Manage all inventory items',
              icon: Icons.inventory_2_outlined,
              color: Colors.indigo,
              onTap: () {
                // Navigate to Item Master screen
                context.go('/cda_page', extra: 'item');
              },
            ),
            const SizedBox(height: 5),

            // Supplier Master Card
            _buildMasterCard(
              context,
              title: 'Supplier Master',
              subtitle: 'Manage your suppliers',
              icon: Icons.people_alt_outlined,
              color: Colors.teal,
              onTap: () {
                // Navigate to Supplier Master screen
                context.go('/cda_page', extra: 'supplier');
              },
            ),
            const SizedBox(height: 5),

            // Supplier Master Card
            _buildMasterCard(
              context,
              title: 'Table Master',
              subtitle: 'Manage your tables',
              icon: Icons.table_restaurant_outlined,
              color: Colors.orange.shade700,
              onTap: () {
                // Navigate to Supplier Master screen
                context.go('/cda_page', extra: 'table');
              },
            ),

            // Spacer to push content up
            const Spacer(),

            // Footer
            Text(
              'Last sync: ${DateTime.now().toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron Icon
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // void _showComingSoon(BuildContext context, String feature) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('$feature Coming Soon'),
  //       content: Text('The $feature feature is currently under development.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
