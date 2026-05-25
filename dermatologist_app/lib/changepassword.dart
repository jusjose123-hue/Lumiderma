import 'package:flutter/material.dart';
import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/myprofile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  final oldpasswordController = TextEditingController();
  final newpasswordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  bool isLoading = false;

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  // ── Theme Sync Palette ──────────────────────────────────────────
  static const _bg = Color(0xff060D12);
  static const _cyanAccent = Color(0xff0EA5E9);
  static const _emeraldAccent = Color(0xff10B981);

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor:
            isError ? const Color(0xffEF4444) : const Color(0xff10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> updatePassword() async {
    final oldPass = oldpasswordController.text.trim();
    final newPass = newpasswordController.text.trim();
    final confirmPass = confirmpasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('All fields are required', isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      /// STEP 1: check old password from DB
      final response = await supabase
          .from('tbl_dermatologist')
          .select('dermatologist_password')
          .eq('dermatologist_id', user.id)
          .single();

      final dbPassword = response['dermatologist_password'] ?? "";

      if (dbPassword != oldPass) {
        _showSnackBar('Incorrect old password', isError: true);
        setState(() => isLoading = false);
        return;
      }

      /// STEP 2: update auth password
      await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );

      /// STEP 3: update your table
      await supabase.from('tbl_dermatologist').update(
          {'dermatologist_password': newPass}).eq('dermatologist_id', user.id);

      _showSnackBar('Password updated successfully');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Myprofile()),
          );
        }
      });
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    oldpasswordController.dispose();
    newpasswordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Glow blobs ──────────────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: _GlowBlob(size: 340, color: _cyanAccent, opacity: 0.18),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowBlob(
                size: 300, color: const Color(0xff6366F1), opacity: 0.12),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// BACK BUTTON
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.10)),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Myprofile(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ICON HERO
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_cyanAccent, _emeraldAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _cyanAccent.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Secure your account with a new password",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14.5,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// OLD PASSWORD
                      buildPasswordField(
                        controller: oldpasswordController,
                        hint: "Old Password",
                        icon: Icons.lock_outline_rounded,
                        obscure: obscureOld,
                        onToggle: () {
                          setState(() {
                            obscureOld = !obscureOld;
                          });
                        },
                      ),

                      /// NEW PASSWORD
                      buildPasswordField(
                        controller: newpasswordController,
                        hint: "New Password",
                        icon: Icons.lock_reset_outlined,
                        obscure: obscureNew,
                        onToggle: () {
                          setState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),

                      /// CONFIRM PASSWORD
                      buildPasswordField(
                        controller: confirmpasswordController,
                        hint: "Confirm Password",
                        icon: Icons.verified_user_outlined,
                        obscure: obscureConfirm,
                        onToggle: () {
                          setState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      /// BUTTON
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [_cyanAccent, _emeraldAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _cyanAccent.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Update Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
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

  /// PASSWORD FIELD
  Widget buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 22,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

// ── Glow Blob Component ──────────────────────────────────────────────────────
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
