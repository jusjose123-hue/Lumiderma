import 'dart:typed_data';

import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/login.dart';
import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:supabase_flutter/supabase_flutter.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController specilizationController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmpasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final TextEditingController proofController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  TextEditingController experienceController = TextEditingController();
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  Uint8List? proofBytes;
  Future<void> insert() async {
    try {
      final email = emailController.text.trim();
      final name = nameController.text.trim();
      final experience = experienceController.text.trim();
      final password = passwordController.text;
      final cpass = confirmpasswordController.text;
      final specilization = specilizationController.text.trim();

      // 1. Check if ANY text field is empty
      if (email.isEmpty ||
          name.isEmpty ||
          password.isEmpty ||
          cpass.isEmpty ||
          experience.isEmpty ||
          specilization.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill in all text fields"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Check if the Profile Image was picked
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please upload a profile picture"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. Check if the Proof Document was picked
      if (proofBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please upload your professional proof"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 4. Password mismatch validation
      if (password != cpass) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.black,
          ),
        );
        return;
      }

      // Show a loading indicator so user knows background tasks are running
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 5. Sign up the user in Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final String? uid = authResponse.user?.id;

      if (uid == null) {
        throw Exception("User registration failed.");
      }

      // 6. Upload assets using the UID
      String? profileImageUrl = await photoUpload(uid);
      String? proofUrl = await proofUpload(uid);

      // 7. Insert into database
      await supabase.from('tbl_dermatologist').insert({
        'dermatologist_id': uid,
        'dermatologist_email': email,
        'dermatologist_name': name,
        'dermatologist_password': password,
        'dermatologist_experience': experience,
        'dermatologist_specilization': specilization,
        'dermatologist_photo': profileImageUrl,
        'dermatologist_proof': proofUrl,
        'dermatologist_status': 'pending'
      });

      // Close loading dialog safely
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration completed"),
          backgroundColor: Colors.black,
        ),
      );

      // Clear fields and selected assets
      emailController.clear();
      passwordController.clear();
      nameController.clear();
      confirmpasswordController.clear();
      specilizationController.clear();
      experienceController.clear();
      proofController.clear();
      setState(() {
        imageBytes = null;
        pickedImage = null;
        proofBytes = null;
        pickedProof = null;
      });

      print("Registration completed");
    } catch (e) {
      // Make sure loading dialog is popped if error happens
      if (Navigator.canPop(context)) Navigator.pop(context);

      print("Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

// Picks the profile picture
  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result =
        await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

// Picks the proof file (supports images and PDFs)
  Future<void> handleProofPick() async {
    file_picker.FilePickerResult? result =
        await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null) return;

    setState(() {
      pickedProof = result.files.first;
      proofBytes = pickedProof!.bytes;
      // Update the text field with the picked file name
      proofController.text = pickedProof!.name;
    });
  }

  /// PROOF UPLOAD
  Future<String?> proofUpload(String uid) async {
    try {
      if (proofBytes == null) return null;

      const bucketName = 'Dermatologist';
      // Saves to a distinct folder: proof/uid.extension
      final filePath = "proof/$uid.${pickedProof!.extension}";

      // Set the content type dynamically based on the file extension
      String contentType = 'image/jpeg';
      if (pickedProof!.extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (pickedProof!.extension == 'png') {
        contentType = 'image/png';
      }

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            proofBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Proof upload error: ${e.toString()}");
      return null;
    }
  }

  /// PHOTO UPLOAD
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'Dermatologist';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage.from(bucketName).uploadBinary(
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

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff0f172a),
                  Color(0xff1e293b),
                  Color(0xff334155),
                ],
              ),
            ),
          ),

          // Positioned(
          //   bottom: -100,
          //   right: -60,
          //   child: Container(
          //     height: 250,
          //     width: 250,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: Colors.purple.withOpacity(0.12),
          //     ),
          //   ),
          // ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: 430,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
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
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Welcome(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // const SizedBox(height: 10),

                      /// LOGO
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff38bdf8),
                              Color(0xff6366f1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Register as Dermatologist",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// PROFILE IMAGE
                      GestureDetector(
                        onTap: handleImagePick,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                gradient: imageBytes == null
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xff38bdf8),
                                          Color(0xff6366f1),
                                        ],
                                      )
                                    : null,
                                image: imageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(imageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imageBytes == null
                                  ? const Icon(
                                      Icons.camera_alt,
                                      size: 45,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// NAME
                      buildField(
                        controller: nameController,
                        hint: "Full Name",
                        icon: Icons.person_outline,
                      ),

                      /// EMAIL
                      buildField(
                        controller: emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                      ),

                      /// SPECIALIZATION
                      buildField(
                        controller: specilizationController,
                        hint: "Specialization",
                        icon: Icons.medical_services_outlined,
                      ),

                      /// EXPERIENCE
                      buildField(
                        controller: experienceController,
                        hint: "Experience",
                        icon: Icons.workspace_premium_outlined,
                      ),

                      /// PROOF
                      GestureDetector(
                        onTap: handleProofPick,
                        child: AbsorbPointer(
                          child: buildField(
                            controller: proofController,
                            hint: "Upload Proof",
                            icon: Icons.upload_file_outlined,
                          ),
                        ),
                      ),

                      /// PASSWORD
                      buildField(
                        controller: passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      /// CONFIRM PASSWORD
                      buildField(
                        controller: confirmpasswordController,
                        hint: "Confirm Password",
                        icon: Icons.verified_user_outlined,
                        isPassword: true,
                      ),

                      const SizedBox(height: 10),

                      /// REMEMBER ME
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (value) {},
                            activeColor: Colors.blue,
                          ),
                          const Text(
                            "Remember me",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xff38bdf8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// BUTTON
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff38bdf8),
                              Color(0xff6366f1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await insert();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Get Started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LOGIN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Login(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Color(0xff38bdf8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// DIVIDER
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// SOCIAL BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          socialButton("assets/go.png"),
                          socialButton("assets/f.webp"),
                          socialButton("assets/go.png"),
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
    );
  }

  /// CUSTOM FIELD
  /// CUSTOM FIELD
  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    bool isConfirmField = controller == confirmpasswordController;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,

        /// PASSWORD VISIBILITY
        obscureText: isPassword
            ? (isConfirmField ? obscureConfirmPassword : obscurePassword)
            : false,

        style: const TextStyle(
          color: Colors.white,
        ),

        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),

          /// EYE ICON
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      if (isConfirmField) {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      } else {
                        obscurePassword = !obscurePassword;
                      }
                    });
                  },
                  icon: Icon(
                    (isConfirmField ? obscureConfirmPassword : obscurePassword)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white,
                  ),
                )
              : null,

          hintText: hint,

          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
          ),
        ),
      ),
    );
  }

  /// SOCIAL BUTTON
  Widget socialButton(String image) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(image),
      ),
    );
  }
}
