import 'dart:typed_data';

import 'package:admin_app/main.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Palette (Synchronized with Ecosystem Dark Ritual Layouts) ────────────────
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
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    fetchComplaint();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Data Management ────────────────────────────────────────
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
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> photoUpload(String uid) async {
    if (imageBytes == null || pickedImage == null) return null;
    try {
      final ext = pickedImage!.extension ?? 'jpg';
      final filePath = "complaints/$uid.$ext";
      await supabase.storage
          .from('complaint')
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: getMimeType(ext),
            ),
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
          "${user.id}_${DateTime.now().millisecondsSinceEpoch}",
        );
      }

      await supabase.from('tbl_complaint').insert({
        'complaint_title': titleController.text.trim(),
        'complaint_content': contentController.text.trim(),
        'user_id': user.id,
        'complaint_date': DateTime.now().toIso8601String(),
        'complaint_status': 'pending',
        'complaint_photo': imageUrl,
        'dermatologist_id': null,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? _error : _accentPurple,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: true,
      expandedHeight: 110,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Submit Complaint",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "We take every concern seriously",
              style: GoogleFonts.outfit(
                color: _subtext,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff1A142A), _bg],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasImage = imageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Attachment (Optional)",
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        GestureDetector(
          onTap: handleImagePick,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: hasImage ? _cardBg : _accentPurple.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasImage ? _accentPink : _border,
                width: hasImage ? 1.5 : 1.2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes!, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 14,
                          right: 60,
                          child: Text(
                            pickedImage?.name ?? "image_attached.jpg",
                            style: GoogleFonts.outfit(
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
                                size: 20,
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
                            color: _accentPurple.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 28,
                            color: _accentPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Upload supporting image",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "PNG, JPG or WEBP up to 10MB",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _subtext,
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

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "COMPLAINT DETAILS",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accentPink,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Title"),
            const SizedBox(height: 6),
            TextFormField(
              controller: titleController,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Please enter a title"
                  : null,
              decoration: _inputDecoration(
                hint: "Brief summary of your complaint",
                icon: Icons.title_rounded,
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel("Description"),
            const SizedBox(height: 6),
            TextFormField(
              controller: contentController,
              maxLines: 5,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Please describe your complaint"
                  : null,
              decoration: _inputDecoration(
                hint: "Provide as much detail as possible…",
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 32),
            Container(height: 1, color: _border),
            const SizedBox(height: 24),

            _buildInfoChip(),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isLoading ? null : _brandGradient,
                  color: isLoading ? _accentPurple.withOpacity(0.5) : null,
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
                  onPressed: isLoading ? null : insertComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Submit Complaint",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _subtext,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        color: const Color(0xff4B5563),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: _accentPurple, size: 20),
      filled: true,
      fillColor: _surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentPurple, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _error, width: 1.8),
      ),
    );
  }

  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _accentPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentPurple.withOpacity(0.2), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: _accentPurple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your complaint will be reviewed within 24 hours.",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
