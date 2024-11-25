import 'package:barber_housecall/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/customer.dart';
import 'screens/barber.dart';
import 'services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service
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
        textTheme: GoogleFonts.jostTextTheme(), // Apply Google Fonts
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/customer': (context) => const CustomerHomeScreen(),
        '/barber': (context) => const BarberHomeScreen(),
      },
    );
  }
}