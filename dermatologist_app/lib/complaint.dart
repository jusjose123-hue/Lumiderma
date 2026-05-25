import 'dart:typed_data';

import 'package:dermatologist_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint>
    with SingleTickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> complaintList = [];

  file_picker.PlatformFile? pickedImage;
  Uint8List? imageBytes;

  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Theme Sync Palette ──────────────────────────────────────────
  static const _bg = Color(0xff060D12);
  static const _cyanAccent = Color(0xff0EA5E9);
  static const _emeraldAccent = Color(0xff10B981);
  static const _error = Color(0xffEF4444);

  @override
  void initState() {
    super.initState();
    fetchComplaint();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────
  Future<void> fetchComplaint() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select()
          .order('complaint_date', ascending: false);
      if (!mounted) return;
      setState(() => complaintList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  Future<void> handleImagePick() async {
    try {
      final result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.image,
        withData: true,
      );
      if (result == null) return;
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("Image Pick Error: $e");
    }
  }

  String getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> photoUpload(String uid) async {
    if (imageBytes == null || pickedImage == null) return null;
    try {
      final ext = pickedImage!.extension ?? 'jpg';
      final filePath = "complaints/$uid.$ext";
      await supabase.storage.from('complaint').uploadBinary(
            filePath,
            imageBytes!,
            fileOptions:
                FileOptions(upsert: true, contentType: getMimeType(ext)),
          );
      return supabase.storage.from('complaint').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> insertComplaint() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnack("Not logged in", isError: true);
        return;
      }

      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await photoUpload(
            "${user.id}_${DateTime.now().millisecondsSinceEpoch}");
      }

      await supabase.from('tbl_complaint').insert({
        'complaint_title': titleController.text.trim(),
        'complaint_content': contentController.text.trim(),
        'dermatologist_id': user.id,
        'complaint_date': DateTime.now().toIso8601String(),
        'complaint_status': 'pending',
        'complaint_photo': imageUrl,
        'user_id': null,
      });

      _showSnack("Complaint submitted successfully");
      titleController.clear();
      contentController.clear();
      setState(() {
        imageBytes = null;
        pickedImage = null;
      });
      await fetchComplaint();
    } catch (e) {
      debugPrint("Insert Error: $e");
      _showSnack("Something went wrong. Please try again.", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isError ? _error : _emeraldAccent,
      content: Row(children: [
        Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600))),
      ]),
    ));
  }

  // ── Build ─────────────────────────────────────────────────
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
            top: size.height * 0.4,
            left: -90,
            child: _GlowBlob(size: 280, color: _emeraldAccent, opacity: 0.12),
          ),
          Positioned(
            bottom: -100,
            right: -40,
            child: _GlowBlob(
                size: 300, color: const Color(0xff6366F1), opacity: 0.12),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPhotoSection(),
                          const SizedBox(height: 24),
                          _buildFormCard(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 120,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 22, top: 12, bottom: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Submit Complaint",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "We take every concern seriously",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        background: Container(color: Colors.transparent),
      ),
    );
  }

  // ── Photo Picker ───────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    final hasImage = imageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "Evidence / Supporting Image",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 1.0,
            ),
          ),
        ),
        GestureDetector(
          onTap: handleImagePick,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasImage
                    ? _cyanAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 16,
                          right: 60,
                          child: Text(
                            pickedImage?.name ?? "attachment_file.jpg",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: _error,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  imageBytes = null;
                                  pickedImage = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cyanAccent.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 26,
                            color: Color(0xff38BDF8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Tap to upload evidence file",
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Supports PNG, JPG, or WEBP (Max 10MB)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form Card ─────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Complaint Details",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xff38BDF8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),

            // ── Title
            _buildLabel("Title"),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              style: const TextStyle(fontSize: 15.5, color: Colors.white),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Please enter a title"
                  : null,
              decoration: _inputDecoration(
                hint: "Brief summary of your complaint",
                icon: Icons.title_rounded,
              ),
            ),

            const SizedBox(height: 22),

            // ── Description
            _buildLabel("Description"),
            const SizedBox(height: 8),
            TextFormField(
              controller: contentController,
              maxLines: 5,
              style: const TextStyle(fontSize: 15.5, color: Colors.white),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Please describe your complaint"
                  : null,
              decoration: _inputDecoration(
                hint: "Provide as much detail as possible…",
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 26),

            // ── Info chip
            _buildInfoChip(),

            const SizedBox(height: 26),

            // ── Submit Button
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
                onPressed: isLoading ? null : insertComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Submit Complaint",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14.5),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _cyanAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _error, width: 1.8),
      ),
    );
  }

  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cyanAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyanAccent.withOpacity(0.15)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xff38BDF8)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your complaint will be reviewed within 24 hours.",
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xff38BDF8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
