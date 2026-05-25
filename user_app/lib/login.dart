import 'package:admin_app/index_page.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/welcompage.dart';
import 'package:admin_app/registration.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isVisible = false;
  bool rememberMe = false;
  bool isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = authResponse.user;
      if (user == null) throw Exception("Login failed");

      final response = await supabase
          .from('tbl_user')
          .select('user_status')
          .eq('user_id', user.id)
          .single();

      final String? status = response['user_status'];

      if (!mounted) return;

      if (status == "rejected") {
        await supabase.auth.signOut();
        _showSnack("Your account has been blocked by admin", isError: true);
      } else if (status == "approved") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IndexPage()),
        );
      } else if (status == "pending") {
        _showSnack("Account pending admin approval", isWarning: true);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xffE53E3E)
            : isWarning
            ? const Color(0xffD97706)
            : const Color(0xff805AD5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D0A14),
      body: Stack(
        children: [
          // ── Glow blobs ──────────────────────────────────────────────
          const Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(
              size: 300,
              color: Color(0xffA855F7),
              opacity: 0.22,
            ),
          ),
          const Positioned(
            top: 260,
            left: -80,
            child: _GlowBlob(
              size: 260,
              color: Color(0xffEC4899),
              opacity: 0.16,
            ),
          ),
          const Positioned(
            bottom: -70,
            right: 40,
            child: _GlowBlob(
              size: 280,
              color: Color(0xff6366F1),
              opacity: 0.18,
            ),
          ),

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
                      // ── Top bar ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleIconBtn(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Welcome(),
                              ),
                            ),
                          ),
                          const _GlassChip(label: "✦  Welcome Back"),
                        ],
                      ),

                      const SizedBox(height: 52),

                      // ── Hero text ──────────────────────────────────
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
                          "✦  Sign In To Continue",
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xffC084FC),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Glow\n    Continues\n                    Here.",
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.06,
                          letterSpacing: -1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: 280,
                        height: 3.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xffA855F7), Color(0xffEC4899)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "Your skin ritual awaits you.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.40),
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Email field ────────────────────────────────
                      _DarkField(
                        controller: emailController,
                        label: "Email Address",
                        hint: "you@example.com",
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 14),

                      // ── Password field ─────────────────────────────
                      _DarkField(
                        controller: passwordController,
                        label: "Password",
                        hint: "Your password",
                        icon: Icons.lock_outline_rounded,
                        obscure: !isVisible,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => isVisible = !isVisible),
                          icon: Icon(
                            isVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Remember me + Forgot ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => rememberMe = !rememberMe),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: rememberMe
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xffA855F7),
                                              Color(0xffEC4899),
                                            ],
                                          )
                                        : null,
                                    color: rememberMe
                                        ? null
                                        : Colors.white.withOpacity(0.08),
                                    border: Border.all(
                                      color: rememberMe
                                          ? Colors.transparent
                                          : Colors.white.withOpacity(0.18),
                                    ),
                                  ),
                                  child: rememberMe
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Remember me",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xffC084FC),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 34),

                      // ── Login CTA ──────────────────────────────────
                      GestureDetector(
                        onTap: isLoading ? null : loginUser,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: isLoading
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xffA855F7).withOpacity(0.5),
                                      const Color(0xffEC4899).withOpacity(0.5),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xffA855F7),
                                      Color(0xffEC4899),
                                    ],
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xffA855F7,
                                ).withOpacity(0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "✦",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Sign up link ───────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Registration(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.40),
                              ),
                              children: const [
                                TextSpan(text: "New here? "),
                                TextSpan(
                                  text: "Create an Account",
                                  style: TextStyle(
                                    color: Color(0xffC084FC),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Divider ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.10),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "or continue with",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.30),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.10),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Social buttons ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialBtn(asset: "assets/go.png"),
                          const SizedBox(width: 16),
                          _SocialBtn(asset: "assets/f.webp"),
                          const SizedBox(width: 16),
                          _SocialBtn(asset: "assets/a.png"),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── Bottom tagline ─────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(const Color(0xffA855F7)),
                                const SizedBox(width: 8),
                                Text(
                                  "Healthy Skin · Happy Life",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.30),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _dot(const Color(0xffEC4899)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Your beauty ritual, elevated.",
                              style: TextStyle(
                                fontSize: 11,
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

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

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.20), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      prefixIcon: Icon(icon, color: const Color(0xffA855F7), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffA855F7), width: 1.5),
      ),
    ),
  );
}

class _SocialBtn extends StatelessWidget {
  final String asset;
  const _SocialBtn({required this.asset});

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    ),
    child: Center(child: Image.asset(asset, width: 26, height: 26)),
  );
}
