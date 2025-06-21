import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_application/screens/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'appointment_details_screen.dart';
import 'home_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        _showSnackbar("User not logged in");
        return;
      }

      final response = await supabase
          .from('appointments')
          .select('id, salon_id, appointment_date, time_slot, status')
          .eq('customer_id', userId)
          .order('appointment_date', ascending: false);

      DateTime now = DateTime.now();

      List<Map<String, dynamic>> upcomingAppointments = [];
      List<Map<String, dynamic>> pastAppointments = [];

      for (var appointment in response) {
        final salon = await supabase
            .from('salons')
            .select('salon_name')
            .eq('id', appointment['salon_id'])
            .single();

        final data = {
          ...appointment,
          'salon_name': salon['salon_name'],
        };

        DateTime appointmentTime = DateTime.parse(appointment['time_slot']);
        if (appointmentTime.isBefore(now) ||
            appointment['status'] == 'Cancelled') {
          pastAppointments.add(data);
        } else {
          upcomingAppointments.add(data);
        }
      }

      setState(() {
        _upcomingAppointments = upcomingAppointments;
        _pastAppointments = pastAppointments;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar("Error fetching appointments.");
      setState(() => _isLoading = false);
    }
  }

  void _goToHomeScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goToHomeScreen();
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Appointments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
            onPressed: _goToHomeScreen,
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F7FA), Color(0xFFE4ECF1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text("Upcoming Appointments",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      _buildAppointmentList(_upcomingAppointments),
                      const SizedBox(height: 30),
                      const Text("Past Appointments",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      _buildAppointmentList(_pastAppointments),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<Map<String, dynamic>> appointments) {
    return appointments.isEmpty
        ? const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(
        child: Text("No Appointments Found",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    String formattedDate = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(appointment['appointment_date']));
    String formattedTime =
    DateFormat.jm().format(DateTime.parse(appointment['time_slot']));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(Icons.calendar_today,
                color: _getStatusColor(appointment['status'])),
            title: Text(appointment['salon_name'],
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("$formattedDate at $formattedTime",
                style: const TextStyle(color: Colors.black87)),
            trailing: _getStatusChip(appointment['status']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AppointmentDetailsScreen(appointmentDetails: appointment),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getStatusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: TextStyle(
            color: _getStatusColor(status), fontWeight: FontWeight.bold),
      ),
      backgroundColor: _getStatusColor(status).withOpacity(0.15),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
