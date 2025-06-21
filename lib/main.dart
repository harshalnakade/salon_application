import 'package:flutter/material.dart';
import 'package:salon_application/screens/admin/admin_appointment_management_screen.dart';
import 'package:salon_application/screens/admin/admin_dashboard_screen.dart';
import 'package:salon_application/screens/admin/admin_salon_management_screen.dart';
import 'package:salon_application/screens/admin/admin_service_managment_screen.dart';
import 'package:salon_application/screens/admin/admin_settings_screens.dart';
import 'package:salon_application/screens/admin/admin_user_management_screen.dart';
import 'package:salon_application/screens/appointment_details_screen.dart'as details;
import 'package:salon_application/screens/appointment_screen.dart';
import 'package:salon_application/screens/booking_confirmation_screen.dart';
import 'package:salon_application/screens/booking_screen.dart';
import 'package:salon_application/screens/home_screen.dart';
import 'package:salon_application/screens/login_screen.dart';
import 'package:salon_application/screens/onboarding_screen.dart';
import 'package:salon_application/screens/profile_screen.dart';
import 'package:salon_application/screens/reviews_screen.dart';
import 'package:salon_application/screens/salon_details_screen.dart';
import 'package:salon_application/screens/salon_owner/salon_appointment_management.dart';
import 'package:salon_application/screens/salon_owner/salon_dashboard_screen.dart';
import 'package:salon_application/screens/salon_owner/salon_manage_reviews_screen.dart';
import 'package:salon_application/screens/salon_owner/salon_service_management_screen.dart';
import 'package:salon_application/screens/salon_owner/salon_settings_screen.dart';
import 'package:salon_application/screens/salon_owner/walk_in_screen.dart';
import 'package:salon_application/screens/saloon_list_screen.dart';
import 'package:salon_application/screens/setting_screen.dart';
import 'package:salon_application/screens/signup_screen.dart';
import 'package:salon_application/screens/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://hokbbdbidpozicsgdfar.supabase.co', // Supabase Project URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhva2JiZGJpZHBvemljc2dkZmFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4OTE2ODQsImV4cCI6MjA1ODQ2NzY4NH0.oxtCXGTTVgP6vP-eW_pdLWUP-b1UOQ42n9QPWchb_40' // Supabase Anon Key
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const SalonHubApp(),
    ),
  );
}


class SalonHubApp extends StatelessWidget {
  const SalonHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salon Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),


      routes: {

        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) =>  HomeScreen(),
        '/appointments': (context) => const AppointmentScreen(),
        '/salons': (context) => const SalonListScreen(),
        '/reviews': (context) => const ReviewsScreen(),


        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/admin_salon_management': (context) => const AdminSalonManagementScreen(),
        '/admin_service_management': (context) => const AdminServiceManagementScreen(),
        '/admin_appointment_management': (context) => const AdminAppointmentManagementScreen(),
        '/admin_user_management': (context) => const AdminUserManagementScreen(),
        '/settings_admin': (context) => const AdminSettingsScreen(),


        '/salon_dashboard': (context) =>  SalonOverviewDashboard(),
        '/salon_service_management': (context) => const SalonServiceManagementScreen(),
        '/salon_appointment_management': (context) => const SalonManageAppointmentsScreen(),
        '/salon_reviews': (context) => const SalonManageReviewsScreen(),
        '/salon_settings': (context) => const SalonSettingsScreen(),
        '/walkin_queue': (context) => const WalkInQueueScreen(),
      },


      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/appointment_details':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => details.AppointmentDetailsScreen(
                appointmentDetails: args, //
              ),
            );


          case '/settings':
            return MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            );

          case '/booking_confirmation':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BookingConfirmationScreen(
                salonName: args['salonName'] ?? "Unknown Salon",
                selectedServices: args['selectedServices'] ?? [],
                selectedDate: args['selectedDate'] ?? "Unknown Date",
                selectedTime: args['selectedTime'] ?? "Unknown Time",
                totalAmount: args['totalAmount'] ?? 0,
                date: args['date'],   // <-- required DateTime
                time: args['time'],   // <-- required DateTime
              ),
            );




          case '/booking':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BookingScreen(
                salonName: args['salonName'] ?? "Unknown Salon",
                salonId: args['salonId'] ?? "",
              ),
            );




          case '/profile':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(),
            );
            case '/salon_details':
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SalonDetailsScreen(
              salonId: args['salonId'], // Pass the salonId
              salonName: args['salonName'] ?? "Unknown Salon",
            ),
          );


          default:
            return MaterialPageRoute(
              builder: (context) => const OnboardingScreen(), // Redirect to Onboarding if route is invalid
            );
        }
      },

      initialRoute: '/login', //  Start with the login screen
    );
  }
}
