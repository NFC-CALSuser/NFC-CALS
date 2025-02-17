import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KSU-Attendance System'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ksu_shieldlogo_colour_rgb.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 45),
              Container(
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle read from tag action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Read from Tag'),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle write to tag action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Write to Tag'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
