import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    String email = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select('id, full_name, role, password')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        _showError("User not found.");
      } else if (password == response['password']) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        String? salonId;
        if (response['role'] == 'Salon Owner') {
          final salonResponse = await supabase
              .from('salons')
              .select('id')
              .eq('owner_id', response['id'])
              .maybeSingle();
          salonId = salonResponse?['id'];
        }

        userProvider.setUserDetails(
          id: response['id'].toString(),
          role: response['role'],
          name: response['full_name'] ?? 'Unknown',
          email: email,
          salonId: salonId,
        );

        switch (response['role']) {
          case 'Admin':
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
            break;
          case 'Salon Owner':
            Navigator.pushReplacementNamed(context, '/salon_dashboard');
            break;
          case 'Customer':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          default:
            _showError("Invalid role assigned.");
        }
      } else {
        _showError("Incorrect password.");
      }
    } catch (e) {
      _showError("Login failed: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4ECF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative soft background layer behind the card
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.08),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),

          // Glassmorphic Login Card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa, size: 60, color: Colors.deepPurple),
                      const SizedBox(height: 10),
                      Text(
                        'Salon Hub',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(_usernameController, 'Email', Icons.email),
                      const SizedBox(height: 15),
                      _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Login', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.black87),
      cursorColor: Colors.deepPurple,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.deepPurple,
          ),
          onPressed: _togglePasswordVisibility,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
