import 'dart:typed_data';

import 'package:admin_app/main.dart';
import 'package:admin_app/myprofile.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _skinTypes = [];

  int? _selectedSkinType;
  String? _gender;

  file_picker.PlatformFile? pickedImage;
  Uint8List? imageBytes;

  String? updatedPhotoUrl;
  String? existingPhotoUrl;

  bool isLoading = false;

  // ── Palette (Perfect Synchronization with Ecosystem Aesthetic) ────────────────
  static const Color _bg = Color(0xff0D0A14);
  static const Color _cardBg = Color(0xff161124);
  static const Color _surfaceAlt = Color(0xff1A142A);
  static const Color _border = Color(0xff2A1F3D);
  static const Color _accentPurple = Color(0xffA855F7);
  static const Color _accentPink = Color(0xffEC4899);
  static const Color _subtext = Color(0xff9CA3AF);
  static const Color _error = Color(0xffEF4444);

  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_accentPurple, _accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    fetchuser();
    _fetchSkinTypes();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
    super.dispose();
  }

  /// FETCH SKIN TYPES
  Future<void> _fetchSkinTypes() async {
    try {
      final response = await supabase
          .from('tbl_type')
          .select('type_id, type_name');

      setState(() {
        _skinTypes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching skin types: $e");
    }
  }

  /// FETCH USER
  Future<void> fetchuser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        nameController.text = response['user_name'] ?? "";
        contactController.text = response['user_contact'] ?? "";
        addressController.text = response['user_address'] ?? "";
        existingPhotoUrl = response['user_photo'];
        _gender = response['user_gender'];
        _selectedSkinType = response['type_id'];
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  /// PICK IMAGE
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

  /// PHOTO UPLOAD
  Future<String?> photoUpload(String uid) async {
    try {
      if (pickedImage == null || imageBytes == null) {
        return existingPhotoUrl;
      }

      const bucketName = "User";
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.${pickedImage!.extension}";
      final filePath = "profile/$uid/$fileName";

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
      print(imageUrl);
      return imageUrl;
    } catch (e) {
      debugPrint("Photo Upload Error: $e");
      return existingPhotoUrl;
    }
  }

  /// UPDATE USER
  Future<void> updateuser() async {
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

      await supabase
          .from('tbl_user')
          .update({
            'user_name': nameController.text.trim(),
            'user_contact': contactController.text.trim(),
            'user_address': addressController.text.trim(),
            'user_gender': _gender,
            'type_id': _selectedSkinType,
            'user_photo': updatedPhotoUrl,
          })
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profile Updated Successfully",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xff00D4AA),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Myprofile()),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $e", style: GoogleFonts.outfit()),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// TEXTFIELD BUILDER
  Widget customField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required Field";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xff4B5563),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: _accentPurple, size: 20),
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _accentPurple, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _error, width: 1.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  /// TOP BAR
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "Edit Profile",
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// PROFILE CONTAINER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _cardBg,
                      border: Border.all(color: _border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// AVATAR ELEMENT CLIP
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
                                  border: Border.all(color: _border, width: 4),
                                  color: _bg,
                                  image: imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : existingPhotoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            existingPhotoUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    imageBytes == null &&
                                        existingPhotoUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 64,
                                        color: _subtext,
                                      )
                                    : null,
                              ),

                              /// CONTAINER ICON SYSTEM BUTTON
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: _bg,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// INPUT FIELD CALLING NODE LAYOUTS
                        customField(
                          controller: nameController,
                          hint: "Enter Name",
                          icon: Icons.person_outline_rounded,
                        ),
                        customField(
                          controller: contactController,
                          hint: "Enter Contact",
                          icon: Icons.phone_android_rounded,
                        ),
                        customField(
                          controller: addressController,
                          hint: "Enter Address",
                          icon: Icons.home_outlined,
                          maxLines: 2,
                        ),

                        /// GENDER SELECTION SPLIT VIEW ROW
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(unselectedWidgetColor: _subtext),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    value: "Male",
                                    groupValue: _gender,
                                    activeColor: _accentPink,
                                    title: Text(
                                      "Male",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _gender = value;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    value: "Female",
                                    groupValue: _gender,
                                    activeColor: _accentPink,
                                    title: Text(
                                      "Female",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _gender = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// DROPDOWN SKIN TYPE INPUT ARCHITECTURE
                        DropdownButtonFormField<int>(
                          value: _selectedSkinType,
                          dropdownColor: _surfaceAlt,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bg,
                            hintText: "Select Skin Type",
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xff4B5563),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: _border,
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: _border,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: _accentPurple,
                                width: 1.8,
                              ),
                            ),
                          ),
                          items: _skinTypes.map((type) {
                            return DropdownMenuItem<int>(
                              value: type['type_id'],
                              child: Text(
                                type['type_name'],
                                style: GoogleFonts.outfit(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSkinType = value;
                            });
                          },
                        ),

                        const SizedBox(height: 35),

                        /// GRADIENT SUBMIT ENGINE TRIGGER ELEVATION
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
                                    offset: const Offset(0, 6),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : updateuser,
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
                                      "Update Profile",
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
