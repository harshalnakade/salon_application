import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salon_application/screens/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingScreen extends StatefulWidget {
  final String salonId;
  final String salonName;

  const BookingScreen({
    super.key,
    required this.salonId,
    required this.salonName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  DateTime? _selectedDate;
  List<Map<String, dynamic>> _services = [];
  List<String> _selectedServiceIds = [];
  int _totalDuration = 0;
  double _totalPrice = 0;
  bool _isLoading = false;

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  List<DateTime> _allSlots = [];
  Set<DateTime> _unavailableSlots = {};
  DateTime? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchSalonServices();
    _fetchSalonTimings();
  }

  Future<void> _fetchSalonServices() async {
    final response = await supabase
        .from('services')
        .select('id, name, duration, price')
        .eq('salon_id', widget.salonId);

    setState(() {
      _services = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchSalonTimings() async {
    final response = await supabase
        .from('salons')
        .select('opening_hours, closing_hours')
        .eq('id', widget.salonId)
        .single();

    if (response != null) {
      setState(() {
        _openingTime = _parseTime(response['opening_hours']);
        _closingTime = _parseTime(response['closing_hours']);
      });
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _toggleService(String serviceId, int duration, double price) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
        _totalDuration -= duration;
        _totalPrice -= price;
      } else {
        _selectedServiceIds.add(serviceId);
        _totalDuration += duration;
        _totalPrice += price;
      }
      _selectedSlot = null;
    });
  }

  Future<void> _generateSlotsAndCheckAvailability() async {
    if (_openingTime == null || _closingTime == null || _selectedDate == null) return;

    _allSlots.clear();
    _unavailableSlots.clear();

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _openingTime!.hour,
      _openingTime!.minute,
    );
    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _closingTime!.hour,
      _closingTime!.minute,
    );

    DateTime current = start;
    while (current.isBefore(end)) {
      _allSlots.add(current);
      current = current.add(const Duration(minutes: 30));
    }

    final existingAppointments = await supabase
        .from('appointments')
        .select('start_time, end_time')
        .eq('salon_id', widget.salonId)
        .eq('appointment_date', _selectedDate!.toIso8601String().split("T")[0]);

    for (final appt in existingAppointments) {
      final apptStart = DateTime.parse(appt['start_time']);
      final apptEnd = DateTime.parse(appt['end_time']);

      for (final slot in _allSlots) {
        final slotEnd = slot.add(const Duration(minutes: 30));
        if (slot.isBefore(apptEnd) && slotEnd.isAfter(apptStart)) {
          _unavailableSlots.add(slot);
        }
      }
    }

    setState(() {});
  }

  int get _requiredSlotCount => (_totalDuration / 30).ceil();

  bool _canSelectSlot(DateTime slot) {
    final startIndex = _allSlots.indexOf(slot);
    if (startIndex == -1 || startIndex + _requiredSlotCount > _allSlots.length) return false;

    for (int i = 0; i < _requiredSlotCount; i++) {
      if (_unavailableSlots.contains(_allSlots[startIndex + i])) return false;
    }
    return true;
  }

  Future<void> _bookAppointment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId.isEmpty || _selectedDate == null || _selectedSlot == null || _selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date, time slot, and at least one service")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = _selectedSlot!;
      final endDateTime = startDateTime.add(Duration(minutes: _totalDuration));

      final existingAppointments = await supabase
          .from('appointments')
          .select()
          .eq('salon_id', widget.salonId)
          .eq('appointment_date', _selectedDate!.toIso8601String().split("T")[0]);

      final hasConflict = existingAppointments.any((appt) {
        final existingStart = DateTime.parse(appt['start_time']);
        final existingEnd = DateTime.parse(appt['end_time']);
        return startDateTime.isBefore(existingEnd) && endDateTime.isAfter(existingStart);
      });

      if (hasConflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This time slot is already booked.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final appointmentInsert = await supabase.from('appointments').insert({
        'salon_id': widget.salonId,
        'customer_id': userId,
        'appointment_date': _selectedDate!.toIso8601String().split("T")[0],
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'time_slot': startDateTime.toIso8601String(),
        'duration_min': _totalDuration,
        'status': 'Confirmed',
      }).select().single();

      final appointmentId = appointmentInsert['id'];

      for (var serviceId in _selectedServiceIds) {
        final service = _services.firstWhere((s) => s['id'] == serviceId);
        await supabase.from('appointment_services').insert({
          'appointment_id': appointmentId,
          'service_id': serviceId,
          'price': service['price'],
          'duration': service['duration'],
        });
      }
      final selectedServicesList = _services
          .where((service) => _selectedServiceIds.contains(service['id']))
          .map((service) => {
        'name': service['name'],
        'price': service['price'],
        'duration': service['duration'],
      })
          .toList();

      Navigator.pushNamed(
        context,
        '/booking_confirmation',
        arguments: {
          'salonName': widget.salonName,
          'selectedServices': selectedServicesList,
          'selectedDate': DateFormat('dd/MM/yyyy').format(_selectedDate!),
          'selectedTime': DateFormat.jm().format(_selectedSlot!),
          'totalAmount': _totalPrice,
          'date': _selectedDate,
          'time': _selectedSlot,
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error booking appointment: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: Text('Book at ${widget.salonName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            const Text("Select Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _selectedSlot = null;
                  });
                  await _generateSlotsAndCheckAvailability();
                }
              },
              child: Text(_selectedDate == null
                  ? "Choose Date"
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null) ...[
              const Text("Select Time Slot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSlots.map((slot) {
                  final isAvailable = _canSelectSlot(slot);
                  final isSelected = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: isAvailable ? () => setState(() => _selectedSlot = slot) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green[200]
                            : isAvailable
                            ? Colors.grey[200]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : isAvailable
                              ? Colors.grey
                              : Colors.red[700]!,
                        ),
                      ),
                      child: Text(
                        DateFormat.jm().format(slot),
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            const Text("Select Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._services.map((service) {
              final isSelected = _selectedServiceIds.contains(service['id']);
              return Card(
                elevation: 1,
                child: CheckboxListTile(
                  title: Text(
                    "${service['name']} (${currencyFormatter.format(service['price'])} - ${service['duration']} min)",
                  ),
                  value: isSelected,
                  onChanged: (_) => _toggleService(
                    service['id'],
                    service['duration'],
                    service['price'].toDouble(),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Text("Total Duration: $_totalDuration min", style: const TextStyle(fontSize: 16)),
            Text("Total Price: ${currencyFormatter.format(_totalPrice)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _bookAppointment,
              icon: const Icon(Icons.check),
              label: const Text("Confirm Appointment"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
