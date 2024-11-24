import 'package:barber_housecall/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'firebase_options.dart';
import 'screens/customer.dart';
import 'screens/barber.dart'; // Import BarberHomeScreen
import 'services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barber Housecall',
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: GoogleFonts.jostTextTheme(), // Use Poppins font
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(), // Map '/' to RootScreen
        '/customer': (context) => const CustomerHomeScreen(),
        '/barber': (context) => const BarberHomeScreen(),
      },
    );
  }
}