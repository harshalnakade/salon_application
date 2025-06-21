import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animations/animations.dart';
import 'user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  void _loadUserDetails() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _fullNameController.text = userProvider.userName;
    _phoneController.text = userProvider.email;
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await _supabase.from('users').update({
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
      }).eq('id', userProvider.userId);

      userProvider.setUserDetails(
        id: userProvider.userId,
        role: userProvider.userRole,
        name: _fullNameController.text,
        email: _phoneController.text,
        salonId: userProvider.salonId,
      );

      _showSnackbar("Profile updated successfully!");
    } catch (e) {
      _showSnackbar("Failed to update profile: $e");
    }

    setState(() {
      _isEditing = false;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blueAccent),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/home');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(userProvider),
                    const SizedBox(height: 20),
                    _buildProfileCard(userProvider),
                    const SizedBox(height: 20),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6D5DF6), Color(0xFF38B6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(Icons.settings, size: 30, color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    return Column(
      children: [
        Hero(
          tag: 'profile-pic',
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 55, color: Colors.blueAccent),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userProvider.userName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          userProvider.email,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: OpenContainer(
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        closedColor: Colors.transparent,
        openBuilder: (context, _) => Scaffold(body: Center(child: Text("Edit Profile Page Coming Soon!"))),
        closedBuilder: (context, openContainer) => Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildTextField("Full Name", Icons.person, _fullNameController, _isEditing),
                _buildTextField("Phone Number", Icons.phone, _phoneController, _isEditing),
                const Divider(height: 30, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.blue),
                  title: Text(
                    'Role: ${userProvider.userRole}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _isEditing ? _buildSaveCancelButtons() : _buildEditButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.blue.shade100, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextFormField(
          controller: controller,
          enabled: isEditable,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.black),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      icon: const Icon(Icons.edit, color: Colors.white),
      label: const Text("Edit Profile", style: TextStyle(fontSize: 16, color: Colors.white)),
      onPressed: () => setState(() => _isEditing = true),
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text("Save", style: TextStyle(fontSize: 16, color: Colors.white)),
          onPressed: _updateProfile,
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          icon: const Icon(Icons.cancel, color: Colors.white),
          label: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.white)),
          onPressed: () => setState(() => _isEditing = false),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("Logout", style: TextStyle(fontSize: 16, color: Colors.white)),
        onPressed: _logout,
      ),
    );
  }
}