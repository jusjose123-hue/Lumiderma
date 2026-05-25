import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/login.dart';
import 'package:dermatologist_app/registration.dart';
import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff060D12),
      body: Stack(
        children: [
          // ── Glow blobs ──────────────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: _GlowBlob(
                size: 340, color: const Color(0xff0EA5E9), opacity: 0.18),
          ),
          Positioned(
            top: size.height * 0.32,
            left: -90,
            child: _GlowBlob(
                size: 280, color: const Color(0xff10B981), opacity: 0.16),
          ),
          Positioned(
            bottom: -100,
            right: -40,
            child: _GlowBlob(
                size: 300, color: const Color(0xff6366F1), opacity: 0.14),
          ),

          // ── Diagonal accent line ─────────────────────────────────────
          Positioned(
            top: 0,
            right: 60,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 1,
                height: size.height * 0.55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff0EA5E9).withOpacity(0.0),
                      const Color(0xff0EA5E9).withOpacity(0.18),
                      const Color(0xff0EA5E9).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassChip(
                            icon: Icons.medical_services_rounded,
                            label: "Dermatologist",
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff0EA5E9),
                                  Color(0xff10B981),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xff0EA5E9).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text("🩺", style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 44),

                      // ── Badge ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff0EA5E9).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: const Color(0xff0EA5E9).withOpacity(0.30)),
                        ),
                        child: const Text(
                          "✦  Smart Dermatology Platform",
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff38BDF8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Headline ──────────────────────────────────────
                      const Text(
                        "Welcome\nDoctor.",
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.06,
                          letterSpacing: -2.0,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Gradient underline
                      Container(
                        width: 70,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Your smart assistant for managing\npatients, bookings & consultations.",
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.65,
                          color: Colors.white.withOpacity(0.50),
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Feature cards ─────────────────────────────────
                      Row(
                        children: [
                          _FeatureCard(
                            emoji: "🩺",
                            label: "Patients",
                            gradientColors: [
                              const Color(0xff0EA5E9).withOpacity(0.22),
                              const Color(0xff0369A1).withOpacity(0.08),
                            ],
                            borderColor:
                                const Color(0xff0EA5E9).withOpacity(0.32),
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            emoji: "📅",
                            label: "Bookings",
                            gradientColors: [
                              const Color(0xff10B981).withOpacity(0.22),
                              const Color(0xff065F46).withOpacity(0.08),
                            ],
                            borderColor:
                                const Color(0xff10B981).withOpacity(0.32),
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            emoji: "💬",
                            label: "Support",
                            gradientColors: [
                              const Color(0xff6366F1).withOpacity(0.22),
                              const Color(0xff3730A3).withOpacity(0.08),
                            ],
                            borderColor:
                                const Color(0xff6366F1).withOpacity(0.32),
                          ),
                        ],
                      ),

                      const SizedBox(height: 44),

                      // ── Stats strip ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(value: "10K+", label: "Patients"),
                            _VertDivider(),
                            _StatItem(value: "98%", label: "Satisfaction"),
                            _VertDivider(),
                            _StatItem(value: "24/7", label: "Support"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Create Account CTA ─────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const Registration()),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff0EA5E9),
                                Color(0xff10B981),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xff0EA5E9).withOpacity(0.40),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("✦",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Login CTA ──────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Guest link ─────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MainScreen()),
                          ),
                          child: Text(
                            "Continue as Guest  →",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.38),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Bottom tagline ─────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(const Color(0xff0EA5E9)),
                                const SizedBox(width: 8),
                                Text(
                                  "Smart · Secure · Modern",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.32),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _dot(const Color(0xff10B981)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Professional Skin Care Experience",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.20),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── Glow Blob ─────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
          ),
        ),
      );
}

// ── Glass Chip ────────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xff38BDF8), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      );
}

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradientColors;
  final Color borderColor;

  const _FeatureCard({
    required this.emoji,
    required this.label,
    required this.gradientColors,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Stat Item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xff38BDF8), Color(0xff34D399)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.42),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

// ── Vertical Divider ──────────────────────────────────────────────────────────

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: Colors.white.withOpacity(0.10),
      );
}
