import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_application/screens/salon_owner/salon_more_details.dart';
import '../user_provider.dart';

class SalonOverviewDashboard extends StatefulWidget {
  const SalonOverviewDashboard({super.key});

  @override
  State<SalonOverviewDashboard> createState() => _SalonOverviewDashboardState();
}

class _SalonOverviewDashboardState extends State<SalonOverviewDashboard> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final salonOwnerName = userProvider.userName;
    final salonOwnerRole = userProvider.userRole;
    final salonId = userProvider.salonId;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Salon Owner Dashboard',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout,color: Colors.white,),
              onPressed: () {
                userProvider.clearUserDetails();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple[50],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $salonOwnerName 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: $salonOwnerRole',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
                Text(
                  'Quick Access',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAccessGrid(context, salonId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, String? salonId) {
    final List<Map<String, dynamic>> quickAccessItems = [
      {
        'title': 'Manage Services',
        'icon': Icons.content_cut,
        'route': '/salon_service_management',
      },
      {
        'title': 'Manage Appointments',
        'icon': Icons.calendar_today,
        'route': '/salon_appointment_management',
      },
      {
        'title': 'Manage Reviews',
        'icon': Icons.reviews,
        'route': '/salon_reviews',
      },
      {
        'title': 'Salon Settings',
        'icon': Icons.settings,
        'route': '/salon_settings',
      },
      {
        'title': 'Walk-in Queue',
        'icon': Icons.people_alt_rounded,
        'route': '/walkin_queue',
      },
      {
        'title': 'Add Salon Images',
        'icon': Icons.add_a_photo,
        'action': (BuildContext context, String? salonId) {
          if (salonId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalonMoreDetailsFormScreen(salonId: salonId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No salon ID found for your account')),
            );
          }
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: quickAccessItems.length,
      itemBuilder: (context, index) {
        final item = quickAccessItems[index];
        return GestureDetector(
          onTap: () {
            if (item.containsKey('action')) {
              item['action'](context, salonId);
            } else if (item.containsKey('route')) {
              Navigator.pushNamed(context, item['route']);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF2EFFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'], size: 38, color: Colors.deepPurpleAccent),
                const SizedBox(height: 10),
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
