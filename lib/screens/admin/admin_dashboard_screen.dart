import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Navigation for each section
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // disables back button
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            )
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          padding: const EdgeInsets.all(20),
          children: [
            _buildDashboardTile(
              icon: Icons.storefront,
              label: 'Manage Salons',
              color: Colors.blue,
              onTap: () => _navigateTo(context, '/admin_salon_management'),
            ),
            _buildDashboardTile(
              icon: Icons.people,
              label: 'Manage Users',
              color: Colors.purple,
              onTap: () => _navigateTo(context, '/admin_user_management'),
            ),
            _buildDashboardTile(
              icon: Icons.bar_chart,
              label: 'Sales Analytics',
              color: Colors.red,
              onTap: () => _navigateTo(context, ''),
            ),
            _buildDashboardTile(
              icon: Icons.settings,
              label: 'Settings',
              color: Colors.teal,
              onTap: () => _navigateTo(context, '/settings_admin'),
            ),
          ],
        ),
      ),
    );
  }


  // Dashboard Tile Widget
  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withOpacity(0.9),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
