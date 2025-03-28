// lib/features/map/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart' as app_auth;
import '../../theme/theme_provider.dart';
import '../../../core/animations/page_transitions.dart';
import '../../navigation/screens/bottom_nav_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Navigate to the main app after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isNavigating) {
        setState(() {
          _isNavigating = true;
        });
        Navigator.of(context).pushReplacement(
          FadePageRoute(page: const BottomNavController()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Memory Lane"),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode 
                ? Icons.wb_sunny_outlined 
                : Icons.nights_stay_outlined,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                    ? Colors.blue.shade800 
                    : Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 60,
                color: themeProvider.isDarkMode 
                    ? Colors.white 
                    : Colors.blue[800],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Welcome to Memory Lane!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode 
                    ? Colors.white 
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Loading your memories...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDarkMode 
                      ? Colors.white70 
                      : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            
            const Spacer(),
            
            // Sign Out Button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}