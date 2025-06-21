import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_provider.dart';

class WalkInQueueScreen extends StatefulWidget {
  const WalkInQueueScreen({super.key});

  @override
  State<WalkInQueueScreen> createState() => _WalkInQueueScreenState();
}

class _WalkInQueueScreenState extends State<WalkInQueueScreen> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _queueChannel;

  List<Map<String, dynamic>> services = [];
  Map<String, int> customerCounts = {};
  int totalServiceDuration = 0;
  int currentQueueTime = 0;
  bool isLoading = true;

  final Color primaryColor = const Color(0xFF7E57C2);
  final Color backgroundColor = const Color(0xFFF3EFEF);
  final Color cardColor = const Color(0xFFFDFDFD);
  final Color textColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _queueChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final salonId = userProvider.salonId;
    if (salonId == null) return;

    final fetchedServices = await fetchServices(salonId);
    final fetchedQueueTime = await fetchCurrentQueueTime(salonId);

    setState(() {
      services = fetchedServices;
      currentQueueTime = fetchedQueueTime;
      customerCounts = {};
      totalServiceDuration = 0;
      isLoading = false;
    });

    _subscribeToQueueUpdates(salonId);
  }

  void _subscribeToQueueUpdates(String salonId) {
    _queueChannel = supabase.channel('walk_in_queue_channel');

    _queueChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'walk_in_queue',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'salon_id',
        value: salonId,
      ),
      callback: (payload) {
        final newTime = payload.newRecord['total_queue_duration'] as int?;
        if (newTime != null) {
          setState(() {
            currentQueueTime = newTime.clamp(0, double.infinity).toInt();
          });
        }
      },
    ).subscribe();
  }

  void _incrementCustomer(String serviceId) {
    setState(() {
      customerCounts[serviceId] = (customerCounts[serviceId] ?? 0) + 1;
      _recalculateTotalDuration();
    });
  }

  void _decrementCustomer(String serviceId) {
    if ((customerCounts[serviceId] ?? 0) > 0) {
      setState(() {
        customerCounts[serviceId] = customerCounts[serviceId]! - 1;
        if (customerCounts[serviceId] == 0) {
          customerCounts.remove(serviceId);
        }
        _recalculateTotalDuration();
      });
    }
  }

  void _recalculateTotalDuration() {
    totalServiceDuration = customerCounts.entries.fold(0, (sum, entry) {
      final service = services.firstWhere((s) => s['id'] == entry.key);
      final duration = (service['duration'] as num).toInt();
      return sum + (duration * entry.value);
    });
  }

  Future<void> _addCustomerToQueue() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final salonId = userProvider.salonId;
    if (salonId == null || totalServiceDuration == 0) return;

    await updateQueueTime(salonId, totalServiceDuration);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customers added to queue')),
    );

    setState(() {
      customerCounts.clear();
      totalServiceDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Walk-in Queue'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCurrentQueueCard(),
              const SizedBox(height: 20),
              _buildServiceList(),
              const SizedBox(height: 10),
              _buildTotalDuration(),
              const SizedBox(height: 20),
              _buildAddToQueueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQueueCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Text(
              'Current Waiting Time: $currentQueueTime min',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (_, index) {
          final service = services[index];
          final count = customerCounts[service['id']] ?? 0;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text("${service['name']} (${service['duration']} min)",
                  style: TextStyle(color: textColor)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.redAccent,
                    onPressed: () => _decrementCustomer(service['id']),
                  ),
                  Text('$count', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.green,
                    onPressed: () => _incrementCustomer(service['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalDuration() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'Total Duration: $totalServiceDuration min',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAddToQueueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: totalServiceDuration > 0 ? _addCustomerToQueue : null,
        icon: const Icon(Icons.queue, color: Colors.white), // 👈 icon color
        label: const Text(
          'Add to Queue',
          style: TextStyle(color: Colors.white), // 👈 text color
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledForegroundColor: Colors.white.withOpacity(0.38),
          disabledBackgroundColor: primaryColor.withOpacity(0.38),
        ),
      ),
    );
  }


  // Supabase functions
  Future<List<Map<String, dynamic>>> fetchServices(String salonId) async {
    final res = await supabase
        .from('services')
        .select('id, name, duration')
        .eq('salon_id', salonId)
        .eq('available', true);

    return res.map((e) => {
      'id': e['id'],
      'name': e['name'],
      'duration': int.parse(e['duration'].toString())
    }).toList();
  }

  Future<int> fetchCurrentQueueTime(String salonId) async {
    final res = await supabase
        .from('walk_in_queue')
        .select('total_queue_duration')
        .eq('salon_id', salonId)
        .maybeSingle();

    if (res == null) {
      await supabase.from('walk_in_queue').insert({
        'salon_id': salonId,
        'total_queue_duration': 0,
      });
      return 0;
    }

    return res['total_queue_duration'] ?? 0;
  }

  Future<void> updateQueueTime(String salonId, int addedTime) async {
    final current = await fetchCurrentQueueTime(salonId);
    final newTime = current + addedTime;

    await supabase.from('walk_in_queue').update({
      'total_queue_duration': newTime,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('salon_id', salonId);
  }
}
