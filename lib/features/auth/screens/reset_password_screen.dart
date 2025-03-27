// lib/features/auth/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../../../core/widgets/custom_text_field.dart';
import '../../theme/theme_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Provider.of<app_auth.AuthProvider>(context, listen: false)
            .resetPassword(_emailController.text.trim());
        
        setState(() {
          _emailSent = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reset Password",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _emailSent ? _buildSuccessScreen() : _buildResetForm(),
      ),
    );
  }

  Widget _buildResetForm() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Forgot your password?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Enter your email address and we'll send you a link to reset your password.",
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 40),

          // Email Input
          CustomTextField(
            controller: _emailController,
            hintText: "Email",
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your email";
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return "Please enter a valid email";
              }
              return null;
            },
          ),
          
          const SizedBox(height: 40),
          
          // Reset Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read,
          size: 100,
          color: themeProvider.isDarkMode ? Colors.blue[400] : Colors.blue[800],
        ),
        const SizedBox(height: 20),
        Text(
          "Check your inbox!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to ${_emailController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Back to Login",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}