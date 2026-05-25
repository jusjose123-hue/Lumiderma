import 'dart:typed_data';

import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/myprofile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController specilizationController = TextEditingController();
  final TextEditingController proofController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  String? updatedPhotoUrl;
  String? updatedProofUrl;

  Uint8List? imageBytes;
  Uint8List? proofBytes;

  String? existingPhotoUrl;
  String? existingProofUrl;

  bool isLoading = false;

  // ── Theme Sync Palette ──────────────────────────────────────────
  static const _bg = Color(0xff060D12);
  static const _cyanAccent = Color(0xff0EA5E9);
  static const _emeraldAccent = Color(0xff10B981);

  @override
  void initState() {
    super.initState();
    fetchdermatologist();
  }

  @override
  void dispose() {
    nameController.dispose();
    experienceController.dispose();
    specilizationController.dispose();
    proofController.dispose();
    super.dispose();
  }

  /// FETCH DATA
  Future<void> fetchdermatologist() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', user.id)
          .single();

      setState(() {
        nameController.text = response['dermatologist_name']?.toString() ?? "";

        experienceController.text =
            response['dermatologist_experience']?.toString() ?? "";

        specilizationController.text =
            response['dermatologist_specilization']?.toString() ?? "";

        existingProofUrl = response['dermatologist_proof']?.toString();
        existingPhotoUrl = response['dermatologist_photo']?.toString();

        // If an old proof URL exists, display the file name parsed from the path
        if (existingProofUrl != null && existingProofUrl!.isNotEmpty) {
          try {
            final uri = Uri.parse(existingProofUrl!);
            proofController.text = uri.pathSegments.last.split('?').first;
          } catch (_) {
            proofController.text = "Uploaded Proof Document";
          }
        }
      });
    } catch (e) {
      debugPrint("Error fetching dermatologist: $e");
    }
  }

  /// IMAGE PICKER
  Future<void> handleImagePick() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

  /// PROOF PICKER (Supports Images & Documents)
  Future<void> handleProofPick() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result == null) return;

    setState(() {
      pickedProof = result.files.first;
      proofBytes = pickedProof!.bytes;
      proofController.text = pickedProof!.name;
    });
  }

  /// UPLOAD PROOF
  Future<String?> proofUpload(String uid) async {
    try {
      if (pickedProof == null || proofBytes == null) {
        return existingProofUrl;
      }

      const bucketName = 'Dermatologist';
      final extension = pickedProof!.extension?.toLowerCase() ?? 'pdf';
      final filePath = "proof/$uid.$extension";

      String contentType;
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            proofBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);

      return "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("Proof upload error: $e");
      return existingProofUrl;
    }
  }

  /// UPLOAD PHOTO
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null || pickedImage == null) {
        return existingPhotoUrl;
      }

      const bucketName = 'Dermatologist';
      final extension = pickedImage!.extension?.toLowerCase() ?? 'jpg';
      final filePath = "profile/$uid.$extension";

      String contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);

      return "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("Photo upload error: $e");
      return existingPhotoUrl;
    }
  }

  /// UPDATE PROFILE
  Future<void> updateDermatologist() async {
    if (!formKey.currentState!.validate()) return;

    try {
      setState(() {
        isLoading = true;
      });

      final user = supabase.auth.currentUser;
      if (user == null) return;

      if (pickedImage != null) {
        updatedPhotoUrl = await photoUpload(user.id);
      } else {
        updatedPhotoUrl = existingPhotoUrl;
      }

      if (pickedProof != null) {
        updatedProofUrl = await proofUpload(user.id);
      } else {
        updatedProofUrl = existingProofUrl;
      }

      await supabase.from('tbl_dermatologist').update({
        'dermatologist_name': nameController.text.trim(),
        'dermatologist_experience': experienceController.text.trim(),
        'dermatologist_specilization': specilizationController.text.trim(),
        'dermatologist_proof': updatedProofUrl,
        'dermatologist_photo': updatedPhotoUrl,
      }).eq('dermatologist_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile Updated Successfully",
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: _emeraldAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Myprofile()),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: const Color(0xffEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// UI
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: Container(
                  width: 430,
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        /// TOP BAR / BACK BUTTON
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
                                  Navigator.pop(context);
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

                        const SizedBox(height: 15),

                        /// PROFILE IMAGE
                        GestureDetector(
                          onTap: handleImagePick,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 130,
                                width: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _cyanAccent.withOpacity(0.4),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _cyanAccent.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  gradient: imageBytes == null &&
                                          existingPhotoUrl == null
                                      ? const LinearGradient(
                                          colors: [
                                            _cyanAccent,
                                            Color(0xff6366F1)
                                          ],
                                        )
                                      : null,
                                  image: imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : existingPhotoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  existingPhotoUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: imageBytes == null &&
                                        existingPhotoUrl == null
                                    ? const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 38,
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
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Update your professional information",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14.5,
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// NAME FIELD
                        buildField(
                          controller: nameController,
                          hint: "Full Name",
                          icon: Icons.person_outline_rounded,
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Name is required" : null,
                        ),

                        /// SPECIALIZATION FIELD
                        buildField(
                          controller: specilizationController,
                          hint: "Specialization",
                          icon: Icons.medical_services_outlined,
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Specialization is required" : null,
                        ),

                        /// EXPERIENCE FIELD
                        buildField(
                          controller: experienceController,
                          hint: "Experience",
                          icon: Icons.workspace_premium_outlined,
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Experience is required" : null,
                        ),

                        /// PROOF FIELD
                        GestureDetector(
                          onTap: handleProofPick,
                          child: AbsorbPointer(
                            child: buildField(
                              controller: proofController,
                              hint: "Upload Proof (PDF, Doc, Image)",
                              icon: Icons.upload_file_outlined,
                              validator: (val) => (val == null || val.trim().isEmpty) ? "Proof document is required" : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// UPDATE BUTTON
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
                            onPressed: isLoading ? null : updateDermatologist,
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
                                    "Update Profile",
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
          ),
        ],
      ),
    );
  }

  /// CUSTOM FIELD WITH FORM VALIDATION
  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
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
        validator: validator,
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
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 15,
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: Color(0xffEF4444)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
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