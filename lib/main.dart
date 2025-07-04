// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'screens/home/welcome_screen.dart';
import 'screens/home/home_page.dart';
import 'screens/tenant_dashboard/search_filter_screen.dart';
import 'screens/tenant_dashboard/hostel_list_screen.dart';
import 'screens/tenant_dashboard/hostel_detail_screen.dart';
import 'screens/tenant_dashboard/booking_screen.dart';
import 'screens/tenant_dashboard/payment_screen.dart';
import 'screens/tenant_dashboard/notification_screen.dart' as tenant;
import 'screens/manager_dashboard/notification_screen.dart' as manager;
import 'screens/manager_dashboard/payments_screen.dart';
import 'screens/tenant_dashboard/profile_screen.dart';
import 'screens/home/virtual_tours.dart';
import 'screens/home/managers_dashboard.dart';
import 'screens/manager_dashboard/room_management_screen.dart';
import 'screens/manager_dashboard/bookings_request.dart';
import 'screens/manager_dashboard/maintenance_repair.dart';
import 'screens/manager_dashboard/settings_screen.dart';
import 'screens/tenant_dashboard/tenant_document_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

class UserProvider extends ChangeNotifier {
  String name = '';
  String contact = '';
  String gender = '';
  String email = '';
  String school = '';
  String programme = '';
  String yearOfStudy = '';

  void setUser({
    required String name,
    required String contact,
    required String gender,
    required String email,
    String school = '',
    String programme = '',
    String yearOfStudy = '',
  }) {
    this.name = name;
    this.contact = contact;
    this.gender = gender;
    this.email = email;
    this.school = school;
    this.programme = programme;
    this.yearOfStudy = yearOfStudy;
    notifyListeners();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message:  [message.messageId]');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDRS_vEqMw3HnJ9wu7BF5J_SEPowfXImWA",
        appId: "1:358026434934:web:cd8fd7be2fdc629af14257",
        messagingSenderId: "358026434934",
        projectId: "hostel-hunt-d3f9d",
        storageBucket: "hostel-hunt-d3f9d.appspot.com",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const HostelHuntApp(),
    ),
  );
}

class HostelHuntApp extends StatelessWidget {
  const HostelHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelHunt',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const HomeScreen(),
        '/search_filter': (context) => const SearchFilterScreen(),
        '/results': (context) => HostelListScreen(),
        '/hostel_detail': (context) => HostelDetailScreen(),
        '/booking': (context) => BookingScreen(),
        '/managerBookingRequest': (context) => BookingsRequestScreen(),
        '/managerMaintenance': (context) => MaintenanceRepairsScreen(),
        '/managerRoomManagement': (context) => RoomManagementScreen(),
        '/managerSettings': (context) => SettingsScreen(),
        '/tenantPayment': (context) => PaymentScreen(),
        '/managerPayment': (context) => PaymentsScreen(),
        '/tenantNotifications': (context) => tenant.NotificationScreen(),
        '/managerNotifications': (context) => manager.NotificationScreen(),
        '/profile': (context) => ProfileScreen(),
        '/virtual-tours': (context) => const VirtualToursScreen(),
        '/manager': (context) => ManagerDashboard(),
        '/room_management': (context) => const RoomManagementScreen(),
        '/tenant_documents': (context) => const TenantDocumentScreen(),
      },
    );
  }
}

class DemoProfileScreen {
}
