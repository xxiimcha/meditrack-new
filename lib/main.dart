import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/patient_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/medication_list_screen.dart';
import 'screens/record_intake_screen.dart';
import 'screens/current_medication.dart';

// Notification packages
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init timezone for scheduled alarms
  tz.initializeTimeZones();

  // Init local notifications
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Request permission for Android 13+
  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();


  runApp(const MeditrackApp());
}

class MeditrackApp extends StatelessWidget {
  const MeditrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => LandingScreen(),
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/': (context) => HomeScreen(),
        '/schedule': (context) => ScheduleScreen(),
        '/list': (context) => const MedicationScheduleListScreen(),
        '/patient_form': (context) => const PatientFormScreen(),
        '/record_intake': (context) => RecordIntakeScreen(),
        '/current_medications': (context) => CurrentMedicationsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
