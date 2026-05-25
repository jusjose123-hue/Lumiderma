import 'package:admin_app/homepage.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/welcompage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR INPUT FORMATTERS
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:supabase_flutter/supabase_flutter.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController =
      TextEditingController();

  List<Map<String, dynamic>> _skinTypes = [];
  int? _selectedSkinType;
  String? _Gender;

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchSkinTypes();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<void> _fetchSkinTypes() async {
    try {
      final response = await supabase
          .from('tbl_type')
          .select('type_id, type_name');
      setState(() => _skinTypes = response);
    } catch (e) {
      debugPrint("Error fetching skin types: $e");
    }
  }

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker
        .FilePicker.pickFiles(type: file_picker.FileType.image, withData: true);
    if (result == null) return;
    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;
    setState(() {});
  }

  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;
      const bucketName = 'User';
      final filePath = "profile/$uid.${pickedImage!.extension}";
      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> insert() async {
    try {
      final email = emailController.text.trim();
      final name = nameController.text.trim();
      final contact = phoneController.text.trim();
      final address = addressController.text.trim();
      final password = passwordController.text;
      final cpass = confirmpasswordController.text;

      // 1. Check if ANY text field is empty
      if (name.isEmpty || 
          email.isEmpty || 
          contact.isEmpty || 
          address.isEmpty || 
          password.isEmpty || 
          cpass.isEmpty) {
        _showSnack("Please fill in all text fields", isError: true);
        return;
      }

      // 2. Strict 10-Digit Contact Validation
      if (contact.length != 10) {
        _showSnack("Phone number must be exactly 10 digits", isError: true);
        return;
      }

      // 3. Profile Image Selection Validation
      if (imageBytes == null) {
        _showSnack("Please upload a profile picture", isError: true);
        return;
      }

      // 4. Skin Type Selection Validation
      if (_selectedSkinType == null) {
        _showSnack("Please select your skin type", isError: true);
        return;
      }

      // 5. Gender Choice Validation
      if (_Gender == null) {
        _showSnack("Please select your gender", isError: true);
        return;
      }

      // 6. Password Matching Validation
      if (password != cpass) {
        _showSnack("Passwords don't match", isError: true);
        return;
      }

      if (password.length < 6) {
        _showSnack("Password must be at least 6 characters long", isError: true);
        return;
      }

      // Display loading overlay dialogue
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffA855F7)),
          ),
        ),
      );

      // Sign up user inside Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final String? uid = authResponse.user?.id;
      if (uid == null) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        throw Exception("User registration failed.");
      }

      // Process asset bucket upload
      String? profileImageUrl = await photoUpload(uid);
      
      // Save full profile details to structural data table
      await supabase.from('tbl_user').insert({
        'user_id': uid,
        'user_email': email,
        'user_name': name,
        'user_password': password,
        'user_contact': contact,
        'user_address': address,
        'user_gender': _Gender,
        'type_id': _selectedSkinType,
        'user_photo': profileImageUrl,
        'user_status': 'pending',
      });

      // Clear loading state safely
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (!mounted) return;
      _showSnack("Registration successful! Welcome 🌸");
      
      // Complete state field teardown
      nameController.clear();
      emailController.clear();
      addressController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmpasswordController.clear();

      setState(() {
        imageBytes = null;
        pickedImage = null;
        _selectedSkinType = null;
        _Gender = null;
      });

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showSnack("Error: $e", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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
            : const Color(0xff805AD5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D0A14),
      body: Stack(
        children: [
          // Background glow blobs
          const Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              size: 320,
              color: Color(0xffA855F7),
              opacity: 0.20,
            ),
          ),
          const Positioned(
            top: 300,
            right: -80,
            child: _GlowBlob(
              size: 260,
              color: Color(0xffEC4899),
              opacity: 0.16,
            ),
          ),
          const Positioned(
            bottom: -80,
            left: 80,
            child: _GlowBlob(
              size: 300,
              color: Color(0xff6366F1),
              opacity: 0.18,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top bar ──────────────────────────────────
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
                              const _GlassChip(label: "✦  Join Us"),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Avatar picker ────────────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: handleImagePick,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: imageBytes == null
                                          ?  LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Color(0xff2D1B4E),
                                                Color(0xff1a1228),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      image: imageBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(imageBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      border: Border.all(
                                        color: const Color(
                                          0xffA855F7,
                                        ).withOpacity(0.6),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xffA855F7,
                                          ).withOpacity(0.35),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: imageBytes == null
                                        ? const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Color(0xffC084FC),
                                            size: 34,
                                          )
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xffA855F7),
                                          Color(0xffEC4899),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xffA855F7,
                                          ).withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  "Create Your Account",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Begin your glow journey today ✨",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── Section label ───────────────────────────
                          _sectionLabel("Personal Info"),
                          const SizedBox(height: 14),

                          _DarkField(
                            controller: nameController,
                            label: "Full Name",
                            hint: "e.g. Aria Chen",
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          _DarkField(
                            controller: emailController,
                            label: "Email Address",
                            hint: "you@example.com",
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _DarkField(
                            controller: phoneController,
                            label: "Phone Number",
                            hint: "9876543210",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly, // Permits numbers only
                              LengthLimitingTextInputFormatter(10),  // Strictly limits input length to 10 characters
                            ],
                          ),
                          const SizedBox(height: 14),
                          _DarkField(
                            controller: addressController,
                            label: "Address",
                            hint: "Your city / location",
                            icon: Icons.location_on_outlined,
                          ),

                          const SizedBox(height: 24),
                          _sectionLabel("Skin Profile"),
                          const SizedBox(height: 14),

                          // ── Skin type dropdown ───────────────────────
                          _DarkDropdown(
                            value: _selectedSkinType,
                            label: "Skin Type",
                            items: _skinTypes
                                .map(
                                  (t) => DropdownMenuItem<int>(
                                    value: t['type_id'],
                                    child: Text(t['type_name']),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSkinType = v),
                          ),

                          const SizedBox(height: 20),

                          // ── Gender chips ─────────────────────────────
                          Row(
                            children: [
                              _GenderChip(
                                label: "Male",
                                emoji: "♂",
                                selected: _Gender == 'Male',
                                onTap: () => setState(() => _Gender = 'Male'),
                              ),
                              const SizedBox(width: 12),
                              _GenderChip(
                                label: "Female",
                                emoji: "♀",
                                selected: _Gender == 'Female',
                                onTap: () => setState(() => _Gender = 'Female'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _sectionLabel("Security"),
                          const SizedBox(height: 14),

                          // ── Password ─────────────────────────────────
                          _DarkField(
                            controller: passwordController,
                            label: "Password",
                            hint: "Min. 8 characters",
                            icon: Icons.lock_outline_rounded,
                            obscure: !isPasswordVisible,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible,
                              ),
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DarkField(
                            controller: confirmpasswordController,
                            label: "Confirm Password",
                            hint: "Re-enter password",
                            icon: Icons.lock_outline_rounded,
                            obscure: !isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible,
                              ),
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── CTA Button ───────────────────────────────
                          GestureDetector(
                            onTap: insert,
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: const LinearGradient(
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Get Started",
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

                          const SizedBox(height: 18),

                          // ── Already have account ─────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Login(),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 14,
                                  ),
                                  children: const [
                                    TextSpan(text: "Already have an account? "),
                                    TextSpan(
                                      text: "Sign In",
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

                          const SizedBox(height: 28),

                          // ── Divider ──────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.10),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  "or continue with",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.35),
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

                          const SizedBox(height: 20),

                          // ── Social buttons ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialBtn(
                                asset: "assets/go.png",
                                label: "Google",
                              ),
                              const SizedBox(width: 16),
                              _SocialBtn(
                                asset: "assets/f.webp",
                                label: "Facebook",
                              ),
                              const SizedBox(width: 16),
                              _SocialBtn(asset: "assets/a.png", label: "Apple"),
                            ],
                          ),

                          const SizedBox(height: 36),
                        ],
                      ),
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

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [Color(0xffA855F7), Color(0xffEC4899)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.50),
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Glow Blob ────────────────────────────────────────────────────────────────

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

// ── Glass Chip ───────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ── Circle Icon Button ────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

// ── Dark Text Field ───────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters; // Added parameter reference

  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // Added to internal input field target
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
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.20),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        prefixIcon: Icon(icon, color: const Color(0xffA855F7), size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.10),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffA855F7), width: 1.5),
        ),
      ),
    );
  }
}

// ── Dark Dropdown ─────────────────────────────────────────────────────────────

class _DarkDropdown extends StatelessWidget {
  final int? value;
  final String label;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: const Color(0xff1C1330),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xffA855F7),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        prefixIcon: const Icon(
          Icons.spa_outlined,
          color: Color(0xffA855F7),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.10),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffA855F7), width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ── Gender Chip ───────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xffA855F7), Color(0xffEC4899)],
                  )
                : null,
            color: selected ? null : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xffA855F7).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 16,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Social Button ─────────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final String asset;
  final String label;

  const _SocialBtn({required this.asset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}