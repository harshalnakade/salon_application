import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salon_application/screens/saloon_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_provider.dart';
import 'profile_screen.dart';
import 'appointment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _salons = [];
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchSalons();
  }

  Future<void> _fetchSalons() async {
    try {
      final response = await supabase.from('salons').select('*');
      setState(() {
        _salons = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showSnackbar("Error fetching salons: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool> _onWillPop() async => true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final List<Widget> _screens = [
      HomeContent(customerName: userProvider.userName, salons: _salons),
      const AppointmentScreen(),
      ProfileScreen(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Salon Hub',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          fit: StackFit.expand,
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
            _screens[_currentIndex],
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 8,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String customerName;
  final List<Map<String, dynamic>> salons;

  const HomeContent({super.key, required this.customerName, required this.salons});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $customerName 👋",
              style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                hintText: "Search for salons...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Featured Salons", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SalonListScreen()),
                  ),
                  child: const Text("View All", style: TextStyle(color: Colors.deepPurple)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            salons.isEmpty
                ? const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Text('No salons available.'),
            ))
                : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: salons.length,
              itemBuilder: (context, index) {
                final salon = salons[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
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
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(Icons.store, color: Colors.deepPurple),
                        ),
                        title: Text(
                          salon['salon_name'] ?? 'Unnamed Salon',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📍 ${salon['address'] ?? 'No address provided'}"),
                            Text("📞 ${salon['contact']}"),
                            Text("🕒 ${salon['opening_hours']} - ${salon['closing_hours']}"),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/salon_details',
                          arguments: {'salonId': salon['id'], 'salonName': salon['salon_name']},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
