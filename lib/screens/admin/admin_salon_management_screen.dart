import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSalonManagementScreen extends StatefulWidget {
  const AdminSalonManagementScreen({super.key});

  @override
  State<AdminSalonManagementScreen> createState() => _AdminSalonManagementScreenState();
}

class _AdminSalonManagementScreenState extends State<AdminSalonManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _salons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSalons();
  }

  void _setLoading(bool value) {
    setState(() => _isLoading = value);
  }

  Future<void> _fetchSalons() async {
    _setLoading(true);
    try {
      final response = await supabase.from('salons').select();
      setState(() {
        _salons = response.map((salon) => {
          'id': salon['id'],
          'name': salon['salon_name'] ?? 'Unnamed Salon',
          'location': salon['address'] ?? 'Unknown Location',
          'rating': salon['rating'] ?? 0.0,
        }).toList();
      });
    } catch (error) {
      _showSnackbar('Failed to fetch salons: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _addSalon(String name, String location) async {
    _setLoading(true);
    try {
      await supabase.from('salons').insert({
        'salon_name': name,
        'address': location,
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });
      _fetchSalons();
      _showSnackbar('Salon added successfully!');
    } catch (error) {
      _showSnackbar('Failed to add salon: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _editSalon(String salonId, String newName, String newLocation) async {
    _setLoading(true);
    try {
      await supabase.from('salons').update({
        'salon_name': newName,
        'address': newLocation,
      }).eq('id', salonId);
      _fetchSalons();
      _showSnackbar('Salon details updated successfully!');
    } catch (error) {
      _showSnackbar('Failed to update salon: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _deleteSalon(String salonId) async {
    _setLoading(true);
    try {
      await supabase.from('salons').delete().eq('id', salonId);
      _fetchSalons();
      _showSnackbar('Salon deleted successfully!');
    } catch (error) {
      _showSnackbar('Failed to delete salon: $error');
    } finally {
      _setLoading(false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blueAccent),
    );
  }

  void _showAddSalonDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Salon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Salon Name')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && locationController.text.trim().isNotEmpty) {
                _addSalon(nameController.text.trim(), locationController.text.trim());
                Navigator.pop(context);
              } else {
                _showSnackbar('Please fill all fields.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSalonDialog(Map<String, dynamic> salon) {
    final TextEditingController nameController = TextEditingController(text: salon['name'] ?? '');
    final TextEditingController locationController = TextEditingController(text: salon['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Salon Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Salon Name')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _editSalon(salon['id'], nameController.text.trim(), locationController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Management'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddSalonDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _salons.length,
        itemBuilder: (context, index) {
          final salon = _salons[index];
          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              title: Text(salon['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Location: ${salon['location']}\nRating: ⭐ ${salon['rating'].toStringAsFixed(1)}"),
              trailing: Wrap(
                spacing: 10,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: () => _showEditSalonDialog(salon)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSalon(salon['id'])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}