// lib/features/map/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Use an alias for your custom AuthProvider
import '../../auth/providers/auth_provider.dart' as app_auth;
import '../../theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the alias when accessing your provider
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    
    // Determine if user signed in with Google (has a provider with ID google.com)
    final isGoogleUser = user?.providerData.any((userInfo) => 
        userInfo.providerId == 'google.com') ?? false;
    
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
                "Your journey of location-based memories starts here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDarkMode 
                      ? Colors.white70 
                      : Colors.grey,
                ),
              ),
            ),
            
            // User information card
            if (user != null) ...[
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode 
                      ? const Color(0xFF1E1E1E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // User profile image (if available)
                    if (user.photoURL != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          user.photoURL!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 30,
                        child: Text(
                          user.displayName?.substring(0, 1).toUpperCase() ?? 
                          user.email?.substring(0, 1).toUpperCase() ?? 
                          "?",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName ?? "Memory Lane User",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: themeProvider.isDarkMode 
                            ? Colors.white 
                            : Colors.black,
                      ),
                    ),
                    Text(
                      user.email ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.isDarkMode 
                            ? Colors.white70 
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isGoogleUser)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                            height: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Google Account",
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.isDarkMode 
                                  ? Colors.white60 
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Explore Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // This would navigate to the map screen in a real implementation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Map screen would open here"),
                      ),
                    );
                  },
                  child: const Text(
                    "Explore Memories",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Sign Out Button
            TextButton.icon(
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
          ],
        ),
      ),
    );
  }
}