import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends State<AdminUserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsersFromDatabase();
  }

  Future<void> _fetchUsersFromDatabase() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('users').select();

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _filteredUsers = List.from(_users);
      });
    } catch (e) {
      _showSnackbar('Error fetching users: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blueAccent),
    );
  }

  /// 🟢 Change Role with Database Update
  Future<void> _changeRole(int index) async {
    final supabase = Supabase.instance.client;
    final currentRole = _filteredUsers[index]['role'];
    final newRole = currentRole == 'Customer' ? 'Salon Owner' : 'Customer';
    final userId = _filteredUsers[index]['id'];

    try {
      // Update role in the database
      await supabase.from('users').update({'role': newRole}).eq('id', userId);

      // Update role locally
      setState(() {
        _filteredUsers[index]['role'] = newRole;
      });

      _showSnackbar("Role updated for ${_filteredUsers[index]['full_name'] ?? 'Unknown User'}");
    } catch (e) {
      _showSnackbar("Error updating role: $e");
    }
  }

  /// 🔴 Delete User with Database Integration
  Future<void> _deleteUser(int index) async {
    final supabase = Supabase.instance.client;
    final userId = _filteredUsers[index]['id'];

    try {
      // Delete user from the database
      await supabase.from('users').delete().eq('id', userId);

      // Remove user locally
      setState(() {
        _filteredUsers.removeAt(index);
      });

      _showSnackbar("User deleted successfully.");
    } catch (e) {
      _showSnackbar("Error deleting user: $e");
    }
  }

  void _searchUser(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) =>
      (user['full_name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (user['email'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _searchUser,
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('No users found.'))
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (user['role'] ?? 'Customer') ==
                          'Customer'
                          ? Colors.blue
                          : Colors.green,
                      child: Icon(
                        (user['role'] ?? 'Customer') == 'Customer'
                            ? Icons.person
                            : Icons.store,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user['full_name'] ?? 'Unknown User',
                      style:
                      const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${user['email'] ?? 'No Email'} • ${user['status'] ?? 'Unknown'}',
                      style: const TextStyle(height: 1.5),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Edit Role') _changeRole(index);
                        if (value == 'Delete') _deleteUser(index);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Edit Role',
                          child: Text('Change Role'),
                        ),
                        const PopupMenuItem(
                          value: 'Delete',
                          child: Text('Delete User'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
