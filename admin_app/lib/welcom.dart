import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/login.dart';
import 'package:userapp/main.dart';
import 'package:userapp/registration.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────
const _bg = Color(0xff0a0f1e);
const _surface = Color(0xff111827);
const _surface2 = Color(0xff1a2235);
const _accent = Color(0xff6366f1);
const _accentLo = Color(0x336366f1);
const _text = Colors.white;
const _textMid = Color(0xffb0bac9);
const _textLow = Color(0xff5a6478);
const _divider = Color(0xff1e2d45);

// Registration uses a slightly different purple — kept to match original
const _regAccent = Color(0xff8B5CF6);
const _regCard = Color(0xff1E293B);
const _regInner = Color(0xff111827);
const _regSub = Color(0xff94A3B8);

// ═════════════════════════════ WELCOME PAGE ═══════════════════════════════════
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // decorative orbs
          Positioned(
            top: -140,
            left: -100,
            child: _Orb(size: 460, color: _accent.withOpacity(.07)),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: _Orb(size: 360, color: _accent.withOpacity(.05)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Brand ──────────────────────────────────────────────────
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentLo,
                      border: Border.all(
                        color: _accent.withOpacity(.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/vg.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'VΔNGUΔRD',
                    style: TextStyle(
                      color: _text,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: _textLow,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // thin divider
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 42),

                  // ── Card ───────────────────────────────────────────────────
                  Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.4),
                          blurRadius: 52,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: _accent.withOpacity(.06),
                          blurRadius: 28,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Welcome 👋',
                          style: TextStyle(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to your account or create a new one\nto access the admin panel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textLow,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── LOGIN button ──────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Login(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── REGISTER button ───────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.app_registration_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _surface2,
                              foregroundColor: _text,
                              elevation: 0,
                              side: BorderSide(color: _divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Registration(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                       
                        TextButton(
                          child: const Text(
                             "Continue as Guest  →",
                            style: TextStyle(
                              color: _textLow,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Nhomepage(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // divider row
                        Row(
                          children: [
                            const Expanded(child: Divider(color: _divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: const Text(
                                'Or continue with',
                                style: TextStyle(color: _textLow, fontSize: 12),
                              ),
                            ),
                            const Expanded(child: Divider(color: _divider)),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // social icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialBtn(asset: 'assets/go.png'),
                            const SizedBox(width: 16),
                            _SocialBtn(asset: 'assets/f.webp'),
                            const SizedBox(width: 16),
                            _SocialBtn(asset: 'assets/a.png'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Text(
                    '© 2026 VΔNGUΔRD. All rights reserved.',
                    style: TextStyle(
                      color: _textLow.withOpacity(.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ LOGIN PAGE ════════════════════════════════════
/// Your original Login UI — wired up with Supabase auth + navigation.
class _LoginPage extends StatefulWidget {
  const _LoginPage();

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final pass = passwordController.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(email: email, password: pass);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Nhomepage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // background image — your original
            Positioned.fill(
              child: Image.asset('assets/bac.jpg', fit: BoxFit.fill),
            ),

            Center(
              child: Card(
                elevation: 10,
                color: const Color.fromARGB(82, 255, 255, 255),
                child: Container(
                  height: 620,
                  width: 390,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(72, 42, 130, 170),
                        Color.fromARGB(78, 121, 46, 19),
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 18,
                    ),
                    child: Column(
                      children: [
                        // back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Card(
                          elevation: 20,
                          child: Container(
                            height: 50,
                            width: 50,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.login,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // email
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.black),
                              hintText: 'Enter the Email',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              prefixIcon: const Icon(Icons.email),
                              prefixIconColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // password
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.black),
                              hintText: 'Enter the Password',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              prefixIcon: const Icon(Icons.password_rounded),
                              suffixIcon: const Icon(
                                Icons.remove_red_eye_outlined,
                              ),
                            ),
                          ),
                        ),

                        // remember me + forgot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // error
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // login button
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 120,
                              vertical: 12,
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),
                        // Or log in with
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  endIndent: 15,
                                  indent: 15,
                                  thickness: 2,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                'Or Log in with',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Expanded(
                                child: Divider(
                                  endIndent: 15,
                                  indent: 15,
                                  thickness: 2,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CircleSocial(asset: 'assets/go.png'),
                            const SizedBox(width: 48),
                            _CircleSocial(asset: 'assets/f.webp'),
                            const SizedBox(width: 48),
                            _CircleSocial(asset: 'assets/a.png'),
                          ],
                        ),
                      ],
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

// ═════════════════════════════ REGISTRATION PAGE ════════════════════════════
/// Your original Registration UI — wired up with Supabase insert.
class _RegistrationPage extends StatefulWidget {
  const _RegistrationPage();

  @override
  State<_RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<_RegistrationPage> {
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color innerBox = Color(0xff111827);
  static const Color purple = Color(0xff8B5CF6);
  static const Color subText = Color(0xff94A3B8);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _insert() async {
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final pass = passwordController.text;

      if (name.isEmpty || email.isEmpty || pass.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }
      if (pass != confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      await supabase.from('tbl_admin').insert({
        'admin_name': name,
        'admin_email': email,
        'admin_password': pass,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name successfully registered!')));
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // ── Left lottie panel ─────────────────────────────────────────────
          if (isWide)
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: innerBox,
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Lottie.asset(
                          'assets/da.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Container(color: Colors.black.withOpacity(.2)),
                  // back button (wide layout — top-left)
                  Positioned(
                    top: 16,
                    left: 12,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Admin Management Terminal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Access secure features, system configuration adjustments, and user telemetry pipelines.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Right form panel ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              height: double.infinity,
              color: cardColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 36,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // back arrow (narrow layout)
                        if (!isWide)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: innerBox,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.login,
                              color: purple,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Registration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please enter your admin credentials to start your setup profile.',
                          style: TextStyle(color: subText, fontSize: 14),
                        ),
                        const SizedBox(height: 36),

                        _buildField(
                          nameController,
                          'Name',
                          'Enter your full name',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          emailController,
                          'Email Address',
                          'admin@domain.com',
                          Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          passwordController,
                          'Password',
                          'Choose a strong password',
                          Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          confirmPasswordController,
                          'Confirm Password',
                          'Verify password selection',
                          Icons.lock_clock_outlined,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: purple,
                                    checkColor: Colors.white,
                                    side: const BorderSide(color: subText),
                                    onChanged: (v) => setState(
                                      () => _rememberMe = v ?? false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: subText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        ElevatedButton(
                          onPressed: _insert,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: innerBox, thickness: 2),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or Log in with',
                                style: TextStyle(color: subText, fontSize: 14),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: innerBox, thickness: 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialBtn(asset: 'assets/go.png'),
                            const SizedBox(width: 20),
                            _SocialBtn(asset: 'assets/f.webp'),
                            const SizedBox(width: 20),
                            _SocialBtn(asset: 'assets/a.png'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _regSub, fontSize: 14),
            filled: true,
            fillColor: _regInner,
            prefixIcon: Icon(icon, color: _regSub, size: 20),
            suffixIcon: isPassword
                ? const Icon(
                    Icons.remove_red_eye_outlined,
                    color: _regSub,
                    size: 20,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _regAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

/// Square social button (used in registration page)
class _SocialBtn extends StatelessWidget {
  final String asset;
  const _SocialBtn({required this.asset});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Container(
        height: 52,
        width: 86,
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(.05)),
        ),
        child: Center(
          child: Image.asset(
            asset,
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Color(0xff94A3B8)),
          ),
        ),
      ),
    );
  }
}

/// Circle social avatar (used in login page)
class _CircleSocial extends StatelessWidget {
  final String asset;
  const _CircleSocial({required this.asset});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 20, backgroundImage: AssetImage(asset));
  }
}

/// Background orb
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
