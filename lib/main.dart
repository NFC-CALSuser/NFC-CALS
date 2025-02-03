import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // Add this line

  // Predefined list of users
  final List<Map<String, String>> _users = [
    {'email': 'user1@example.com', 'password': 'password1'},
    {'email': 'user2@example.com', 'password': 'password2'},
    {'email': 'admin', 'password': 'admin'},
    {'email': '442106884', 'password': '442106884'}, // Add student credentials
    {'email': 'inst', 'password': 'inst'}, // Add instructor credentials
  ];

  void _login() {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      bool userFound = _users.any(
          (user) => user['email'] == email && user['password'] == password);

      if (userFound) {
        if (email == 'admin' && password == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        } else if (email == '442106884' && password == '442106884') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
          );
        } else if (email == 'inst' && password == 'inst') { // Add instructor navigation
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstructorDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Blue area for your logo and app title
              Container(
                height: size.height * 0.35, // Increased slightly to fit text
                width: double.infinity,
                color: Colors.blue,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/ksu_shieldlogo_colour_rgb.png',
                        width: 170,
                        height: 170,
                      ),
                      const SizedBox(height: 20),
                      // Text below the logo
                      const Text(
                        'Classroom Attendance Logging System Using NFC',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // White container for the form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email TextField
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Additional validation can be added here
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password TextField
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText, // Modify this line
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 231, 225, 225),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Forgot Password & Signup (optional)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Handle forgot password action
                              },
                              child: const Text('Forgot Password?'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Handle sign up action
                              },
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Container(
        color: Colors.white, // Set background color to blue
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/ksu_shieldlogo_colour_rgb.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 45),
              Container(
                color: Colors.white, // Set background color to white
                child: ElevatedButton(
                  onPressed: () {
                    // Handle read from tag action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white, // Set button background to white
                    foregroundColor:
                        Colors.blue, // Set button text color to blue
                  ),
                  child: const Text('Read from Tag'),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white, // Set background color to white
                child: ElevatedButton(
                  onPressed: () {
                    // Handle write to tag action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white, // Set button background to white
                    foregroundColor:
                        Colors.blue, // Set button text color to blue
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

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              const SizedBox(height: 20),
              // NFC Card Design
              Container(
                width: 300,
                height: 200, // Increased height to accommodate name
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // NFC symbol
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(
                        Icons.wifi_tethering,
                        size: 30,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Student ID Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'ريان احمد الزهراني',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '442106884',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Icon(
                                Icons.touch_app,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tap to mark attendance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Handle viewing attendance history
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('View Attendance History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              const SizedBox(height: 20),
              const Text(
                'Dr. Mohammed Abdullah',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Handle start session
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Start Session'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle view attendance reports
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('View Attendance Reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
