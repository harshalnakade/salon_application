import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // =====================
          // Account Information
          // =====================
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('Account Information'),
            subtitle: const Text('Update your profile details'),
            onTap: () {
              // Navigate to Profile Screen
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Divider(),

          // =====================
          // Notifications
          // =====================
          SwitchListTile(
            value: _notificationsEnabled,
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive updates about appointments & offers'),
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),

          // =====================
          // Theme Mode (Light/Dark)
          // =====================
          SwitchListTile(
            value: _darkModeEnabled,
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          const Divider(),

          // =====================
          // Language Settings
          // =====================
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blue),
            title: const Text('Language'),
            subtitle: const Text('English (Default)'),
            onTap: () {
              // Future Language Selection Dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          const Divider(),

          // =====================
          // Logout Button
          // =====================
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              // Logout Logic
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
