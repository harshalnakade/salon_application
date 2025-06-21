import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../user_provider.dart';


class BookingScreen extends StatefulWidget {
  final String salonId;
  final String salonName;

  const BookingScreen({super.key, required this.salonId, required this.salonName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  bool isLoading = false;

  final List<String> timeSlots = [
    '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM',
    '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'
  ];

  Future<void> _bookAppointment() async {
    if (selectedTime == null) {
      _showSnackbar("Please select a time slot.");
      return;
    }

    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final customerId = userProvider.userId; // Fetch customer ID from provider

    final response = await Supabase.instance.client.rpc(
      'safe_book_appointment',
      params: {
        'salon_id': widget.salonId,
        'slot_time': selectedTime,
        'customer_id': customerId,
      },
    );

    setState(() => isLoading = false);

    if (response == true) {
      _showSnackbar("Appointment booked successfully!");
      Navigator.pop(context); // Go back to previous screen
    } else {
      _showSnackbar("Slot already taken. Try another time.");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.salonName, style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Date", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Text("${selectedDate.toLocal()}".split(' ')[0]),
            ),
            const SizedBox(height: 20),
            Text("Select Time Slot", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timeSlots.map((slot) {
                bool isSelected = selectedTime == slot;
                return GestureDetector(
                  onTap: () => setState(() => selectedTime = slot),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(slot, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Book Now", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
