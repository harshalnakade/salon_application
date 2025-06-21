import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String salonName;
  final List<Map<String, dynamic>> selectedServices;
  final String selectedDate;
  final String selectedTime;
  final double totalAmount;
  final DateTime date;
  final DateTime time;

  const BookingConfirmationScreen({
    super.key,
    required this.salonName,
    required this.selectedServices,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalAmount,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20).copyWith(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Your appointment at", style: Theme.of(context).textTheme.titleMedium),
              Text(
                salonName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text("Services:", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...selectedServices.map((service) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(service['name']),
                subtitle: Text("${service['duration']} mins"),
                trailing: Text(currencyFormatter.format(service['price'])),
              )),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text("Date: $selectedDate"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text("Time: $selectedTime"),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Total: ${currencyFormatter.format(totalAmount)}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("Back to Home"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
