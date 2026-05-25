import 'package:admin_app/main.dart';
import 'package:admin_app/myprofile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Palette (Synchronized with Ecosystem Dark Ritual Style) ────────────────
  static const Color _bg = Color(0xff0D0A14);
  static const Color _cardBg = Color(0xff161124);
  static const Color _border = Color(0xff2A1F3D);
  static const Color _accentPurple = Color(0xffA855F7);
  static const Color _accentPink = Color(0xffEC4899);
  static const Color _subtext = Color(0xff9CA3AF);
  static const Color _error = Color(0xffEF4444);

  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_accentPurple, _accentPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? _error : _accentPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
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

      final response = await supabase
          .from('tbl_user')
          .select('user_password')
          .eq('user_id', user.id)
          .single();

      final dbPassword = response['user_password'] ?? "";

      if (dbPassword != oldPass) {
        _showSnackBar('Incorrect old password', isError: true);
        setState(() => isLoading = false);
        return;
      }

      await supabase.auth.updateUser(UserAttributes(password: newPass));

      await supabase
          .from('tbl_user')
          .update({'user_password': newPass})
          .eq('user_id', user.id);

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

  Widget passwordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _accentPurple, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: _subtext,
              size: 20,
            ),
          ),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xff4B5563),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff1A142A), _bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: _cardBg,
                    border: Border.all(color: _border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _bg,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
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
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: _accentPurple.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "Change Password",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create a new secure password",
                        style: GoogleFonts.outfit(
                          color: _subtext,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 35),
                      passwordField(
                        controller: oldpasswordController,
                        hint: "Old Password",
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscureOld,
                        onToggle: () {
                          setState(() {
                            obscureOld = !obscureOld;
                          });
                        },
                      ),
                      passwordField(
                        controller: newpasswordController,
                        hint: "New Password",
                        icon: Icons.lock_reset_rounded,
                        obscureText: obscureNew,
                        onToggle: () {
                          setState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                      passwordField(
                        controller: confirmpasswordController,
                        hint: "Confirm Password",
                        icon: Icons.verified_user_outlined,
                        obscureText: obscureConfirm,
                        onToggle: () {
                          setState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: isLoading ? null : _brandGradient,
                            color: isLoading
                                ? _accentPurple.withOpacity(0.5)
                                : null,
                            boxShadow: [
                              if (!isLoading)
                                BoxShadow(
                                  color: _accentPurple.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Update Password",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
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
        ),
      ),
    );
  }
}
