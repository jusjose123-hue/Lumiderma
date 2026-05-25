import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Needed to reference the global 'supabase' client


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
    
    // 1. Setup the animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // 2. The 4-second delay timer that handles checking login state
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        // Check if user has an active Supabase session
        final session = supabase.auth.currentSession;
        
        // Dynamic target routing based on authentications status
        Widget targetScreen = (session != null) ? const MainScreen() : const Welcome();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
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
      backgroundColor: const Color(0xFF0A0A0F), // Matches your homepage background
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
                      color: Color(0xff0EA5E9).withOpacity(0.3),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/ECG.json',
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.wb_sunny_rounded,
                    size: 100,
                    color:  Color(0xff0EA5E9),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  "💉DermaConnect",
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color:  Color(0xff0EA5E9),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Seamlessly manage and streamline patient bookings.",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white60,
                  
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color:  Color(0xff0EA5E9),
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