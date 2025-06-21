import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salon_application/screens/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentDetails;

  const AppointmentDetailsScreen({super.key, required this.appointmentDetails});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> services = [];
  bool isLoading = true;

  final _commentController = TextEditingController();
  int? _rating;
  bool _isSubmitting = false;
  bool _reviewSubmitted = false;
  Map<String, dynamic>? _existingReview;

  @override
  void initState() {
    super.initState();
    fetchAppointmentDetails();
  }

  Future<void> fetchAppointmentDetails() async {
    try {
      final appointmentId = widget.appointmentDetails['id'];
      final userId = Provider.of<UserProvider>(context, listen: false).userId;

      final serviceResponse = await supabase
          .from('appointment_services')
          .select('price, services(name)')
          .eq('appointment_id', appointmentId);

      final reviewResponse = await supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      setState(() {
        services = serviceResponse.map<Map<String, dynamic>>((item) {
          return {
            'name': item['services']['name'],
            'price': item['price']
          };
        }).toList();
        _reviewSubmitted = reviewResponse != null;
        _existingReview = reviewResponse;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching appointment details or review: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitReview(String userId) async {
    if (_rating == null || _commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final salonId = widget.appointmentDetails['salon_id'];
      final appointmentId = widget.appointmentDetails['id'];

      final response = await supabase.from('reviews').insert({
        'salon_id': salonId,
        'user_id': userId,
        'appointment_id': appointmentId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      }).select().single();

      setState(() {
        _reviewSubmitted = true;
        _existingReview = response;
      });
    } catch (e) {
      print('Review submission failed: $e');
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  double _calculateTotalAmount() {
    return services.fold(0.0, (sum, s) => sum + (s['price'] as num).toDouble());
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown Date';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatTime(dynamic time) {
    try {
      final parsed = DateTime.parse(time);
      return DateFormat.jm().format(parsed);
    } catch (e) {
      return time ?? 'Unknown Time';
    }
  }

  Widget _buildStatusChip(String status) {
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
      backgroundColor: chipColor.withOpacity(0.15),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReviewSection(String userId) {
    if (_reviewSubmitted && _existingReview != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(thickness: 1),
            const Text("Your Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Rating: ${_existingReview!['rating']} Stars"),
            Text("Comment: ${_existingReview!['comment']}"),
            if (_existingReview!['reply'] != null && (_existingReview!['reply'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("Salon Reply: ${_existingReview!['reply']}", style: const TextStyle(color: Colors.blueAccent)),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        const Text("Leave a Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: "Rating",
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white70,
          ),
          items: List.generate(5, (index) => index + 1).map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text("$value Star${value > 1 ? 's' : ''}"),
            );
          }).toList(),
          onChanged: (value) => setState(() => _rating = value),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Comment",
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : () => _submitReview(userId),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Submit Review", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;
    final details = widget.appointmentDetails;
    final salonName = details['salon_name'] ?? 'Unknown Salon';
    final status = details['status'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.purple.shade400,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFCEFF9), Color(0xFFE0F7FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salonName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        "${_formatDate(details['appointment_date'])} at ${_formatTime(details['time_slot'])}",
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Services Booked:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ...services.map((service) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 5.0),
                    child: Text("• ${service['name']} - ₹${service['price']}", style: const TextStyle(fontSize: 16)),
                  )),
                  const SizedBox(height: 15),
                  Text(
                    "Total Amount: ₹ ${_calculateTotalAmount()}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 15),
                  _buildStatusChip(status),
                  if (status == 'Completed') _buildReviewSection(userId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
