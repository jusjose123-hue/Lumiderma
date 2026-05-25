import 'package:flutter/material.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/main.dart';
import 'package:lottie/lottie.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  // Theme Colors
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color innerBoxColor = Color(0xff111827);
  static const Color accentPurple = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool rememberMe = false;

  // 1. Independent visibility state variables tracking password obfuscation
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> insert() async {
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
        return;
      }

      await supabase.from('tbl_admin').insert({
        'admin_name': name,
        'admin_email': email,
        'admin_password': password,
      });
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Nhomepage()),
          (r) => false,
        );
      }

      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          
          Expanded(
            flex: 8,
            child: Container(
              height: double.infinity,
              color: cardColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48.0,
                    vertical: 36.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: innerBoxColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.login,
                                color: accentPurple,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Registration",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Please enter your admin credentials to start your setup profile.",
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                          const SizedBox(height: 36),
                          _buildWebTextField(
                            controller: nameController,
                            label: "Name",
                            hint: "Enter your full name",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          _buildWebTextField(
                            controller: emailController,
                            label: "Email Address",
                            hint: "admin@domain.com",
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          // 2. Updated Password Field using persistent class visibility states
                          _buildWebTextField(
                            controller: passwordController,
                            label: "Password",
                            hint: "Choose a strong password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // 3. Updated Confirm Password Field using independent state metrics
                          _buildWebTextField(
                            controller: confirmPasswordController,
                            label: "Confirm Password",
                            hint: "Verify password selection",
                            icon: Icons.lock_clock_outlined,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
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
                                      value: rememberMe,
                                      activeColor: accentPurple,
                                      checkColor: Colors.white,
                                      side: const BorderSide(
                                        color: subTextColor,
                                      ),
                                      onChanged: (value) {
                                        setState(
                                          () => rememberMe = value ?? false,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: accentPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: insert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Get started",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(
                                  color: innerBoxColor,
                                  thickness: 2,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Or Log in with",
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: innerBoxColor,
                                  thickness: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildWebSocialButton("assets/go.png"),
                              const SizedBox(width: 20),
                              _buildWebSocialButton("assets/f.webp"),
                              const SizedBox(width: 20),
                              _buildWebSocialButton("assets/a.png"),
                            ],
                          ),
                        ],
                      ),
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

  // 4. Refactored helper method to accept custom visibility states and callbacks
  Widget _buildWebTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
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
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
            filled: true,
            fillColor: innerBoxColor,
            prefixIcon: Icon(icon, color: subTextColor, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: subTextColor,
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
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
              borderSide: const BorderSide(color: accentPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSocialButton(String assetPath) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        width: 86,
        decoration: BoxDecoration(
          color: innerBoxColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: subTextColor),
          ),
        ),
      ),
    );
  }
}
