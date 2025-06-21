import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_provider.dart';

class SalonSettingsScreen extends StatefulWidget {
  const SalonSettingsScreen({super.key});

  @override
  State<SalonSettingsScreen> createState() => _SalonSettingsScreenState();
}

class _SalonSettingsScreenState extends State<SalonSettingsScreen> {
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _notificationsEnabled = true;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchSalonDetails();
  }

  Future<void> _fetchSalonDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final response = await supabase
          .from('salons')
          .select()
          .eq('owner_id', userProvider.userId)
          .maybeSingle();

      if (response != null) {
        _salonNameController.text = response['salon_name'] ?? '';
        _contactNumberController.text = response['contact'] ?? '';
        _addressController.text = response['address'] ?? '';

        _openingTime = _parseTime(response['opening_hours']);
        _closingTime = _parseTime(response['closing_hours']);
      }

      setState(() {});
    } catch (e) {
      print('Error fetching salon details: $e');
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      DateTime dateTime;
      if (timeString.contains('AM') || timeString.contains('PM')) {
        dateTime = DateFormat('h:mm a').parse(timeString);
      } else {
        dateTime = DateFormat('HH:mm').parse(timeString);
      }
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      print("Time parsing error: $e");
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _selectTime({required bool isOpening}) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime ?? TimeOfDay.now() : _closingTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isOpening) {
          _openingTime = pickedTime;
        } else {
          _closingTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final openingHours = _openingTime != null ? _formatTimeOfDay(_openingTime!) : '';
    final closingHours = _closingTime != null ? _formatTimeOfDay(_closingTime!) : '';

    try {
      await supabase.from('salons').update({
        'salon_name': _salonNameController.text,
        'contact': _contactNumberController.text,
        'address': _addressController.text,
        'opening_hours': openingHours,
        'closing_hours': closingHours,
      }).eq('owner_id', userProvider.userId);

      await supabase.from('users').update({
        'full_name': _salonNameController.text,
        'phone': _contactNumberController.text,
      }).eq('id', userProvider.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings saved successfully.")),
      );
    } catch (e) {
      print('Save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving settings: $e")),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(

        automaticallyImplyLeading: false,
        title: const Text('Salon Settings',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildStyledTextField(_salonNameController, 'Salon Name'),
            const SizedBox(height: 15),
            _buildStyledTextField(_contactNumberController, 'Contact Number',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildStyledTextField(_addressController, 'Address'),
            const SizedBox(height: 25),
            const Text(
              "Business Hours",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text("Opening Time"),
                        subtitle: Text(_openingTime?.format(context) ?? 'Not Set'),
                        leading: const Icon(Icons.access_time, color: Colors.blue),
                        onTap: () => _selectTime(isOpening: true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text("Closing Time"),
                        subtitle: Text(_closingTime?.format(context) ?? 'Not Set'),
                        leading: const Icon(Icons.access_time, color: Colors.redAccent),
                        onTap: () => _selectTime(isOpening: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            const Divider(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.save,),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.edit, color: Colors.blueGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}