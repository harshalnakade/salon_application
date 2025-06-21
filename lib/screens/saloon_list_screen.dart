import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salon_application/screens/salon_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SalonListScreen extends StatefulWidget {
  const SalonListScreen({super.key});

  @override
  State<SalonListScreen> createState() => _SalonListScreenState();
}

class _SalonListScreenState extends State<SalonListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _salons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalons();
  }

  Future<void> _fetchSalons() async {
    try {
      final response = await _supabase.from('salons').select('*');
      setState(() {
        _salons = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackbar("Error fetching salons: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.deepPurple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text('Salons Near You', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _salons.isEmpty
          ? Center(
        child: Text(
          'No salons available.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: _salons.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final salon = _salons[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SalonDetailsScreen(
                    salonId: salon['id'],
                    salonName: salon['salon_name'] ?? 'Unknown Salon',
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              shadowColor: Colors.deepPurple.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.storefront, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salon['salon_name'] ?? 'Unnamed Salon',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            salon['address'] ?? 'No address provided',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
