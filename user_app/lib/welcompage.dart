import 'package:flutter/material.dart';
import 'package:admin_app/homepage.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/registration.dart';

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
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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
      backgroundColor: const Color(0xff0D0A14),
      body: Stack(
        children: [
          // ── Background mesh blobs ──────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              size: 320,
              color: const Color(0xffA855F7),
              opacity: 0.22,
            ),
          ),
          Positioned(
            top: size.height * 0.28,
            right: -90,
            child: _GlowBlob(
              size: 260,
              color: const Color(0xffEC4899),
              opacity: 0.18,
            ),
          ),
          Positioned(
            bottom: -100,
            left: size.width * 0.2,
            child: _GlowBlob(
              size: 300,
              color: const Color(0xff6366F1),
              opacity: 0.20,
            ),
          ),

        
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.network(
                'https://grainy-gradients.vercel.app/noise.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassChip(label: "✦  Skin Ritual"),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xffA855F7), Color(0xffEC4899)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xffA855F7,
                                  ).withOpacity(0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text("🌸", style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 38),

                      // Hero badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffA855F7).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xffA855F7).withOpacity(0.35),
                          ),
                        ),
                        child: const Text(
                          "✦  Your Daily Glow Companion",
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffC084FC),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main headline
                      const Text(
                        "Radiant\n     Skin Starts\n                   Here.",
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -1.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Accent underline
                      Container(
                        width: 270,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xffA855F7), Color(0xffEC4899)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Track your skin journey, discover\ncurated products & consult top\ndermatologists — all in one place.",
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.65,
                          color: Color(0xff9CA3AF),
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Feature cards row
                      Row(
                        children: [
                          _FeatureCard(
                            emoji: "🧴",
                            label: "Skin\nCare",
                            gradient: [
                              const Color(0xffA855F7).withOpacity(0.25),
                              const Color(0xff7C3AED).withOpacity(0.10),
                            ],
                            borderColor: const Color(
                              0xffA855F7,
                            ).withOpacity(0.35),
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            emoji: "🛒",
                            label: "Smart\nShop",
                            gradient: [
                              const Color(0xffEC4899).withOpacity(0.25),
                              const Color(0xffBE185D).withOpacity(0.10),
                            ],
                            borderColor: const Color(
                              0xffEC4899,
                            ).withOpacity(0.35),
                          ),
                          const SizedBox(width: 12),
                          _FeatureCard(
                            emoji: "👩‍⚕️",
                            label: "Expert\nDoctors",
                            gradient: [
                              const Color(0xff6366F1).withOpacity(0.25),
                              const Color(0xff4338CA).withOpacity(0.10),
                            ],
                            borderColor: const Color(
                              0xff6366F1,
                            ).withOpacity(0.35),
                          ),
                        ],
                      ),

                      const SizedBox(height: 44),

                      // Create Account CTA
                      _PrimaryButton(
                        label: "Create Account",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Registration(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Login button
                      _OutlineButton(
                        label: "Sign In",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Guest
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Homepage()),
                          ),
                          child: const Text(
                            "Continue as Guest  →",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff6B7280),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Bottom tagline
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(const Color(0xffA855F7)),
                                const SizedBox(width: 8),
                                const Text(
                                  "Healthy Skin · Happy Life",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _dot(const Color(0xffEC4899)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Your beauty ritual, elevated.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff4B5563),
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
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Glow blob background ─────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ── Glass chip ───────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Feature card ─────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final Color borderColor;

  const _FeatureCard({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
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
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Primary button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xffA855F7), Color(0xffEC4899)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffA855F7).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "✦",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Outline button ───────────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
