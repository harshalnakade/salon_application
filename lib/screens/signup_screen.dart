import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonAddressController = TextEditingController();
  final TextEditingController _salonContactController = TextEditingController();

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  String _selectedRole = 'Customer';
  bool _acceptTerms = false;

  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String? _validateTimeSelection() {
    if (_selectedRole == 'Salon Owner') {
      if (_openingTime == null || _closingTime == null) {
        return 'Please select opening and closing hours';
      }
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  void _submitForm() async {
    final timeValidationMessage = _validateTimeSelection();

    if (_formKey.currentState!.validate() && _acceptTerms && timeValidationMessage == null) {
      final supabase = Supabase.instance.client;

      try {
        final email = _emailController.text.trim();

        final existingUser = await supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (existingUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User already exists with this email.')),
          );
          return;
        }

        final userInsertResponse = await supabase
            .from('users')
            .insert({
          'full_name': _fullNameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': _selectedRole,
          'status': 'Active',
          'created_at': DateTime.now().toIso8601String(),
        })
            .select('id')
            .single();

        final String newUserId = userInsertResponse['id'];

        final userCheck = await supabase
            .from('users')
            .select('id')
            .eq('id', newUserId)
            .maybeSingle();

        if (userCheck == null) {
          throw Exception('User insertion failed. Please try again.');
        }

        if (_selectedRole == 'Salon Owner') {
          await Future.delayed(const Duration(milliseconds: 500));

          await supabase.from('salons').insert({
            'owner_id': newUserId,
            'salon_name': _salonNameController.text.trim(),
            'address': _salonAddressController.text.trim(),
            'contact': _salonContactController.text.trim(),
            'opening_hours': _formatTimeOfDay(_openingTime!),
            'closing_hours': _formatTimeOfDay(_closingTime!),
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign Up Successful!')),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });

      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected Error: $error')),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions.')),
      );
    } else if (timeValidationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeValidationMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              Text("Create an account", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTextField(_fullNameController, 'Full Name', Icons.person),
              _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
              _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock, obscureText: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'Salon Owner', child: Text('Salon Owner')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              if (_selectedRole == 'Salon Owner') ...[
                const SizedBox(height: 20),
                _buildTextField(_salonNameController, 'Salon Name', Icons.store),
                _buildTextField(_salonAddressController, 'Salon Address', Icons.location_on),
                _buildTextField(_salonContactController, 'Salon Contact', Icons.phone),
                ListTile(
                  title: Text('Opening Hours: ${_openingTime != null ? _formatTimeOfDay(_openingTime!) : "Select Time"}'),
                  leading: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, true),
                ),
                ListTile(
                  title: Text('Closing Hours: ${_closingTime != null ? _formatTimeOfDay(_closingTime!) : "Select Time"}'),
                  leading: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, false),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) => setState(() => _acceptTerms = value!),
                  ),
                  const Expanded(
                    child: Text('I accept the Terms and Conditions'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitForm,
                icon: const Icon(Icons.check),
                label: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Confirm Password' && value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }
}