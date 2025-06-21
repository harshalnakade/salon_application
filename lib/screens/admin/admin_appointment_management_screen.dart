import 'package:flutter/material.dart';

class AdminAppointmentManagementScreen extends StatefulWidget {
  const AdminAppointmentManagementScreen({super.key});

  @override
  State<AdminAppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AdminAppointmentManagementScreen> {
  final List<Map<String, dynamic>> _appointments = [
    {'user': 'John Doe', 'date': '2025-04-10', 'time': '3:00 PM', 'status': 'Confirmed'},
    {'user': 'Jane Smith', 'date': '2025-03-25', 'time': '11:00 AM', 'status': 'Completed'},
    {'user': 'Alice Johnson', 'date': '2025-03-20', 'time': '5:00 PM', 'status': 'Cancelled'},
    {'user': 'Mark Wilson', 'date': '2025-04-15', 'time': '1:00 PM', 'status': 'Confirmed'},
  ];

  String _selectedStatus = 'All';

  // Filtered Appointment Logic
  List<Map<String, dynamic>> get _filteredAppointments {
    if (_selectedStatus == 'All') return _appointments;
    return _appointments.where((appointment) => appointment['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Appointment List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = _filteredAppointments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text("${appointment['user']}"),
                      subtitle: Text("${appointment['date']} at ${appointment['time']}"),
                      trailing: _getStatusChip(appointment['status']),
                      onTap: () {
                        _showAppointmentDetails(appointment);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display Appointment Details
  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Appointment Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User: ${appointment['user']}"),
            Text("Date: ${appointment['date']}"),
            Text("Time: ${appointment['time']}"),
            Text("Status: ${appointment['status']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // Status Chip for better UI
  Widget _getStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Confirmed':
        chipColor = Colors.green;
        break;
      case 'Completed':
        chipColor = Colors.blue;
        break;
      case 'Cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: chipColor.withOpacity(0.2),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.bold),
    );
  }
}
