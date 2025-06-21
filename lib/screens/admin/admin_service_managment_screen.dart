import 'package:flutter/material.dart';

class AdminServiceManagementScreen extends StatefulWidget {
  const AdminServiceManagementScreen({super.key});

  @override
  State<AdminServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<AdminServiceManagementScreen> {
  final List<Map<String, dynamic>> _services = [
    {'name': 'Haircut', 'price': 500, 'description': 'Professional haircut for all hair types.'},
    {'name': 'Facial', 'price': 800, 'description': 'Glowing facial treatment with herbal products.'},
    {'name': 'Spa Therapy', 'price': 1000, 'description': 'Relaxing spa session with aromatherapy.'},
  ];

  // Add New Service Dialog
  void _addService() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Service Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.add({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'description': descriptionController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Delete Service
  void _deleteService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  // Edit Service Dialog
  void _editService(int index) {
    final TextEditingController nameController = TextEditingController(text: _services[index]['name']);
    final TextEditingController priceController = TextEditingController(text: _services[index]['price'].toString());
    final TextEditingController descriptionController = TextEditingController(text: _services[index]['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Service Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services[index] = {
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'description': descriptionController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addService,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: ListTile(
              title: Text(service['name']),
              subtitle: Text("₹${service['price']} - ${service['description']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editService(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteService(index),
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