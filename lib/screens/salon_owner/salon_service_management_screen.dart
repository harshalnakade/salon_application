import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_provider.dart';

class SalonServiceManagementScreen extends StatefulWidget {
  const SalonServiceManagementScreen({super.key});

  @override
  State<SalonServiceManagementScreen> createState() =>
      _SalonServiceManagementScreenState();
}

class _SalonServiceManagementScreenState
    extends State<SalonServiceManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    final salonId = Provider.of<UserProvider>(context, listen: false).salonId;
    if (salonId == null || salonId.isEmpty) {
      _showSnackbar('Salon ID is missing. Please log in again.');
      return;
    }
    try {
      final response = await supabase
          .from('services')
          .select('*')
          .eq('salon_id', salonId);

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackbar('Error fetching services: $e');
    }
  }

  Future<void> _addServiceToDatabase(Map<String, dynamic> service) async {
    final salonId = Provider.of<UserProvider>(context, listen: false).salonId;
    if (salonId == null || salonId.isEmpty) {
      _showSnackbar('Salon ID is missing. Please log in again.');
      return;
    }
    try {
      service['salon_id'] = salonId;
      await supabase.from('services').insert(service);
      _fetchServices();
      _showSnackbar('Service added successfully.');
    } catch (e) {
      _showSnackbar('Error adding service: $e');
    }
  }

  Future<void> _updateService(String id, Map<String, dynamic> updatedService) async {
    try {
      await supabase.from('services').update(updatedService).eq('id', id);
      _fetchServices();
      _showSnackbar('Service updated successfully.');
    } catch (e) {
      _showSnackbar('Error updating service: $e');
    }
  }

  Future<void> _deleteService(String id) async {
    try {
      await supabase.from('services').delete().eq('id', id);
      _fetchServices();
      _showSnackbar('Service deleted successfully.');
    } catch (e) {
      _showSnackbar('Error deleting service: $e');
    }
  }

  Future<void> _toggleAvailability(String id, bool isAvailable) async {
    try {
      await supabase.from('services').update({'available': isAvailable}).eq('id', id);
      _fetchServices();
      _showSnackbar('Service availability updated.');
    } catch (e) {
      _showSnackbar('Error updating availability: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showServiceDialog({
    bool isEdit = false,
    Map<String, dynamic>? existingService,
  }) {
    final nameController = TextEditingController(
        text: isEdit && existingService != null ? existingService['name'] : '');

    final priceController = TextEditingController(
        text: isEdit && existingService != null
            ? existingService['price'].toString()
            : '');

    final durationController = TextEditingController(
        text: isEdit && existingService != null
            ? existingService['duration']
            : '');

    final bool isAvailable = existingService?['available'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Service' : 'Add New Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Service Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (e.g., 30 mins)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Available"),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() {
                          existingService?['available'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    durationController.text.isEmpty) {
                  _showSnackbar('Please fill all fields.');
                  return;
                }

                final newService = {
                  'name': nameController.text.trim(),
                  'price': int.tryParse(priceController.text.trim()) ?? 0,
                  'duration': durationController.text.trim(),
                  'available': existingService?['available'] ?? true,
                };

                if (isEdit && existingService != null) {
                  await _updateService(existingService['id'], newService);
                } else {
                  await _addServiceToDatabase(newService);
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Update Service' : 'Add Service'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Service Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.add,color: Colors.white,), onPressed: () => _showServiceDialog()),
        ],
      ),
      body: _services.isEmpty
          ? const Center(child: Text('No services available. Add a new service.'))
          : ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          final bool isAvailable = service['available'] ?? true;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 3,
            child: ListTile(
              title: Text(service['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("₹${service['price']} • ${service['duration']}", style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    isAvailable ? "Available" : "Not Available",
                    style: TextStyle(
                      fontSize: 14,
                      color: isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: isAvailable,
                    onChanged: (value) => _toggleAvailability(service['id'].toString(), value),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showServiceDialog(isEdit: true, existingService: service),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteService(service['id'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
