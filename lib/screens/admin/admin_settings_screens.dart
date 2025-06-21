import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_provider.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  // Logout Logic
  void _logout(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).clearUserDetails();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Change Password Logic
  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _passwordController = TextEditingController();
        final TextEditingController _confirmPasswordController = TextEditingController();
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
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
              onPressed: () async {
                if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fields cannot be empty.')),
                  );
                  return;
                }

                if (_passwordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                  return;
                }

                try {
                  final supabase = Supabase.instance.client;

                  await supabase
                      .from('users')
                      .update({
                    'password': _passwordController.text,  // Directly storing the password
                  })
                      .eq('id', userProvider.userId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully.')),
                  );
                  Navigator.pop(context); // Close dialog
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $error')),
                  );
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  // Edit Profile Logic
  void _editProfile(BuildContext context, String currentName, String currentEmail) {
    showDialog(
      context: context,
      builder: (context) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final TextEditingController _nameController = TextEditingController(text: currentName);
        final TextEditingController _emailController = TextEditingController(text: currentEmail);

        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
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
              onPressed: () async {
                if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fields cannot be empty.')),
                  );
                  return;
                }

                try {
                  final supabase = Supabase.instance.client;

                  await supabase
                      .from('users')
                      .update({
                    'full_name': _nameController.text,
                    'email': _emailController.text,
                  })
                      .eq('id', userProvider.userId);

                  // Update details in provider
                  userProvider.setUserDetails(
                    id: userProvider.userId!,
                    role: userProvider.userRole!,
                    name: _nameController.text,
                    email: _emailController.text,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully.')),
                  );
                  Navigator.pop(context); // Close dialog
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $error')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String adminName = userProvider.userName;
    final String adminEmail = userProvider.email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Settings'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text('Edit Profile ($adminName)'),
              onTap: () => _editProfile(context, adminName, adminEmail),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.lock, color: Colors.orange),
              title: const Text('Change Password'),
              onTap: () => _changePassword(context),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
