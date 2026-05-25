import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/main.dart';
import 'package:userapp/welcom.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
      
        final session = supabase.auth.currentSession;
        
      
        // Widget targetScreen = (session != null) ? const Nhomepage() : const WelcomePage();
 Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Nhomepage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff8B5CF6).withOpacity(0.3),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/da.json',
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 100,
                    color: Color(0xff8B5CF6),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "VΔNGUΔRD(lumiderma)",
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color:  Color.fromARGB(255, 187, 92, 246),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "ADMIN TERMINAL",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white60,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 50),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xff8B5CF6),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}