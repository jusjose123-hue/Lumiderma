import 'package:flutter/material.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/main.dart';

// ─── Color Tokens (dashboard theme) ──────────────────────────────────────────
const _bg = Color(0xff0a0f1e);
const _surface = Color(0xff111827);
const _surface2 = Color(0xff1a2235);
const _sidebar = Color(0xff080d18);
const _accent = Color(0xff6366f1);
const _accentLo = Color(0x336366f1);
const _text = Colors.white;
const _textMid = Color(0xffb0bac9);
const _textLow = Color(0xff5a6478);
const _divider = Color(0xff1e2d45);
const _error = Color(0xffef4444);

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await supabase
          .from('tbl_admin')
          .select()
          .eq('admin_email', _emailCtrl.text.trim())
          .eq('admin_password', _passwordCtrl.text)
          .maybeSingle();

      if (response == null) {
        throw Exception("Invalid email or password. Please try again.");
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Nhomepage()),
          (r) => false, 
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 320,
              color: _sidebar,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // subtle grid
                  CustomPaint(painter: _GridPainter()),

                  // center icon orb
                  Positioned(
                    top: 0,
                    bottom: 200,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentLo,
                          border: Border.all(
                            color: _accent.withOpacity(.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          color: _accent,
                          size: 44,
                        ),
                      ),
                    ),
                  ),

                  // bottom brand block
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_sidebar.withOpacity(0), _sidebar],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // logo + name
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _accentLo,
                                  border: Border.all(
                                    color: _accent.withOpacity(.5),
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/vg.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'VΔNGUΔRD',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Admin\nManagement\nTerminal',
                            style: TextStyle(
                              color: _text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Access secure features and\nsystem configuration.',
                            style: TextStyle(
                              color: _textMid,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // indicator dots
                          Row(
                            children: List.generate(
                              3,
                              (i) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  width: i == 0 ? 22 : 8,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i == 0 ? _accent : _divider,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ══════════════════════ MAIN AREA ══════════════════════════════════
          Expanded(
            child: Column(
              children: [
                // ── Topbar (matches dashboard) ────────────────────────────
                Container(
                  height: 60,
                  color: _surface,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // indigo brand chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentLo,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accent.withOpacity(.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'VΔNGUΔRD',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form area ─────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // heading
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: _text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.only(left: 13),
                                child: Text(
                                  'Welcome back — enter your credentials to continue.',
                                  style: TextStyle(
                                    color: _textLow,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Divider(color: _divider),
                              const SizedBox(height: 24),

                              // email label + field
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  color: _textMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 13.5,
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                                decoration: _fieldDecor(
                                  hint: 'admin@domain.com',
                                  icon: Icons.email_outlined,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // password label + field
                              const Text(
                                'Password',
                                style: TextStyle(
                                  color: _textMid,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 13.5,
                                ),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Minimum 6 characters'
                                    : null,
                                decoration: _fieldDecor(
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _textLow,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // remember me + forgot password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _remember,
                                          activeColor: _accent,
                                          checkColor: Colors.white,
                                          side: BorderSide(color: _textLow),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          onChanged: (v) => setState(
                                            () => _remember = v ?? false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          color: _textMid,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: _accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // error banner
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xffef4444).withOpacity(.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xffef4444).withOpacity(.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xffef4444),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xffef4444),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // login button
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    disabledBackgroundColor: _accentLo,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: .3,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Or log in with divider
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: _divider),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'Or Log in with',
                                      style: TextStyle(
                                        color: _textLow,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: _divider),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // social buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _socialTile('assets/go.png'),
                                  const SizedBox(width: 14),
                                  _socialTile('assets/f.webp'),
                                  const SizedBox(width: 14),
                                  _socialTile('assets/a.png'),
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
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecor({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textLow, fontSize: 13),
      prefixIcon: Icon(icon, color: _textLow, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface2,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffef4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffef4444), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xffef4444), fontSize: 11.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _socialTile(String asset) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 48,
        width: 80,
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _divider),
        ),
        child: Center(
          child: Image.asset(
            asset,
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: _textLow, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Subtle grid background for left panel ────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff6366f1).withOpacity(.04)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
