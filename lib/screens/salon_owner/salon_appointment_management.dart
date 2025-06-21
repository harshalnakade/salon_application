import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_provider.dart';

class SalonManageAppointmentsScreen extends StatefulWidget {
  const SalonManageAppointmentsScreen({super.key});

  @override
  State<SalonManageAppointmentsScreen> createState() =>
      _SalonManageAppointmentsScreenState();
}

class _SalonManageAppointmentsScreenState
    extends State<SalonManageAppointmentsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final salonId = userProvider.salonId;

    if (salonId == null) {
      _showSnackbar("Error: Salon ID not found");
      return;
    }

    try {
      final response = await supabase
          .from('appointments')
          .select('''
            id,
            customer_id,
            appointment_date,
            time_slot,
            status,
            users(full_name),
            appointment_services(
              duration,
              price,
              services(name)
            )
          ''')
          .eq('salon_id', salonId)
          .order('appointment_date', ascending: true);

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar("Error fetching appointments: $e");
    }
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      await supabase
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);

      setState(() {
        _appointments = _appointments.map((appointment) {
          if (appointment['id'] == appointmentId) {
            appointment['status'] = newStatus;
          }
          return appointment;
        }).toList();
      });

      _showSnackbar("Appointment updated successfully");
    } catch (e) {
      _showSnackbar("Error updating status: $e");
    }
  }

  List<Map<String, dynamic>> _filteredAppointments(String status) {
    return _appointments
        .where((appointment) => appointment['status'] == status)
        .toList();
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentServices =
    List<Map<String, dynamic>>.from(appointment['appointment_services'] ?? []);
    final totalDuration = appointmentServices.fold<int>(
      0,
          (sum, item) => sum + ((item['duration'] ?? 0) as int),
    );

    final serviceNames = appointmentServices
        .map((s) => s['services']?['name'] ?? 'Unknown')
        .join(', ');

    final rawDate = appointment['appointment_date'];
    final rawTime = appointment['time_slot'];
    final customerName = appointment['users']?['full_name'] ?? 'Customer';

    String formattedDate = 'Invalid date';
    String formattedTime = 'Invalid time';

    try {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
      formattedTime = DateFormat('hh:mm a').format(DateTime.parse(rawTime));
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) =>
                      _updateAppointmentStatus(appointment['id'], value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'Confirmed', child: Text('Mark as Confirmed')),
                    const PopupMenuItem(
                        value: 'Completed', child: Text('Mark as Completed')),
                    const PopupMenuItem(
                        value: 'Cancelled', child: Text('Mark as Cancelled')),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1.2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 20, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.design_services, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serviceNames,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  "$totalDuration mins",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment['status'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.deepPurple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Manage Appointments'),
          centerTitle: true,
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildAppointmentList('Confirmed'),
            _buildAppointmentList('Completed'),
            _buildAppointmentList('Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final filteredAppointments = _filteredAppointments(status);

    if (filteredAppointments.isEmpty) {
      return const Center(
        child: Text(
          'No appointments found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(filteredAppointments[index]);
        },
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
