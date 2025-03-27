// lib/features/auth/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'login_screen.dart';
import 'register_screen.dart';
import '../../theme/theme_provider.dart';
import '../../../core/animations/animated_widgets.dart';
import '../../../core/animations/page_transitions.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme toggle button
          AnimatedIconButton(
            icon: Icon(
              themeProvider.isDarkMode 
                ? Icons.wb_sunny_outlined 
                : Icons.nights_stay_outlined,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: themeProvider.isDarkMode
                ? [
                    Colors.blue[900]!,
                    Colors.blue[800]!,
                    Colors.blue[700]!,
                  ]
                : [
                    Colors.blue[900]!,
                    Colors.blue[800]!,
                    Colors.blue[400]!,
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FadeInWidget(
                duration: const Duration(milliseconds: 800),
                child: SlideInWidget(
                  offset: const Offset(-30, 0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Memory Lane",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Your location-based digital time capsule",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FadeInWidget(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 300),
                child: SlideInWidget(
                  offset: const Offset(0, 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuint,
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? const Color(0xFF121212) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          // App description
                          AnimatedContent(
                            initialDelay: const Duration(milliseconds: 600),
                            staggerDelay: const Duration(milliseconds: 100),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Anchor your memories to places",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Create location-based digital time capsules containing photos, videos, audio recordings, or written reflections that can only be accessed when physically visiting that location again.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          
                          // Buttons
                          AnimatedContent(
                            initialDelay: const Duration(milliseconds: 800),
                            staggerDelay: const Duration(milliseconds: 150),
                            slideOffset: const Offset(0, 20),
                            fadeIn: true,
                            slideIn: true,
                            children: [
                              // Login Button
                              AnimatedButton(
                                color: Colors.blue[800],
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      page: const LoginScreen(),
                                      direction: SlideDirection.up,
                                    ),
                                  );
                                },
                                child: const Text("Log In"),
                              ),
                              const SizedBox(height: 20),
                              // Register Button
                              AnimatedButton(
                                isOutlined: true,
                                color: Colors.blue[800],
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      page: const RegisterScreen(),
                                      direction: SlideDirection.up,
                                    ),
                                  );
                                },
                                child: const Text("Create Account"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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

class AnimatedIconButton extends StatefulWidget {
  final Icon icon;
  final VoidCallback onPressed;

  const AnimatedIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value,
              child: widget.icon,
            );
          },
        ),
      ),
    );
  }
}