import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/config_service.dart';
import 'services/encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.initialize();
  await EncryptionService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KSU-Attendance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Add this line
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}
