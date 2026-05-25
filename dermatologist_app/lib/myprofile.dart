import 'package:dermatologist_app/changepassword.dart';
import 'package:dermatologist_app/complaint.dart';
import 'package:dermatologist_app/editprofile.dart';
import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/my_complaint.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for opening PDFs/DocumentsExternally

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});

  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile>
    with SingleTickerProviderStateMixin {
  dynamic photo = '';
  String name = '';
  String email = '';
  String experience = '';
  String proof = '';
  String specilization = '';

  TextEditingController proofController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Theme Sync Palette ──────────────────────────────────────────
  static const _bg = Color(0xff060D12);
  static const _cyanAccent = Color(0xff0EA5E9);
  static const _emeraldAccent = Color(0xff10B981);

  @override
  void initState() {
    super.initState();
    fetchdermatologist();

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
    proofController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchdermatologist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        name = response['dermatologist_name'] ?? '';
        email = response['dermatologist_email'] ?? '';
        photo = response['dermatologist_photo'] ?? '';
        experience = response['dermatologist_experience'] ?? '';
        proof = response['dermatologist_proof'] ?? '';
        specilization = response['dermatologist_specilization'] ?? '';
        proofController.text = proof;
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  /// Handles viewing both Images & Document files
  Future<void> handleProofPick() async {
    if (proof.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xff0F172A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: const Text("No Proof Uploaded",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
              "This dermatologist has not uploaded a proof document yet.",
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close",
                  style: TextStyle(
                      color: _cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Clean URL query parameters to accurately check the extension
    final cleanUrl = proof.split('?').first.toLowerCase();
    final isImage = cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png');

    if (isImage) {
      // Open standard image modal smoothly
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: InteractiveViewer(
              child: Image.network(
                proof,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text("Unable to load image",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Launch documents natively outside the app (PDFs, Docx, etc.)
      try {
        final Uri url = Uri.parse(proof);
        if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
           // Successfully loaded external document handler
        } else {
          throw 'Could not launch file stream';
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening document: $e"),
            backgroundColor: const Color(0xffEF4444),
          ),
        );
      }
    }
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
            top: size.height * 0.35,
            left: -90,
            child: _GlowBlob(size: 280, color: _emeraldAccent, opacity: 0.14),
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
                child: RefreshIndicator(
                  color: _cyanAccent,
                  backgroundColor: const Color(0xff0F172A),
                  onRefresh: fetchdermatologist,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildAppBar(context),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeroCard(),
                            const SizedBox(height: 24),
                            _buildInfoSection(),
                            const SizedBox(height: 16),
                            _buildProofTile(),
                            const SizedBox(height: 32),
                            _buildActionButtons(context),
                          ]),
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

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 22, top: 8, bottom: 8),
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
      title: const Text(
        "My Profile",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 22, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 20,
              ),
              offset: const Offset(0, 48),
              color: const Color(0xff0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              elevation: 8,
              onSelected: (value) async {
                if (value == 'help') {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => Complaint()));
                } else if (value == 'complaints') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyComplaintsPage()));
                } else if (value == 'signout') {
                  await supabase.auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Welcome()),
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                _menuItem(Icons.help_outline_rounded, 'help', "Help Center",
                    Colors.white),
                _menuItem(Icons.inbox_outlined, 'complaints', "My Complaints",
                    Colors.white),
                const PopupMenuDivider(height: 1),
                _menuItem(Icons.logout_rounded, 'signout', "Sign Out",
                    const Color(0xffFCA5A5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      IconData icon, String value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color.withOpacity(0.8), size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cyanAccent.withOpacity(0.4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _cyanAccent.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withOpacity(0.05),
              backgroundImage: (photo != null && photo.toString().isNotEmpty)
                  ? NetworkImage(photo.toString())
                  : null,
              child: (photo == null || photo.toString().isEmpty)
                  ? const Text("🩺", style: TextStyle(fontSize: 36))
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            name.isEmpty ? "—" : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email.isEmpty ? "—" : email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 22),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _cyanAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _cyanAccent.withOpacity(0.30)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "✦  Verified Dermatologist",
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff38BDF8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Section ──────────────────────────────────────────
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Professional Details"),
        const SizedBox(height: 10),
        _infoTile(
          icon: Icons.workspace_premium_outlined,
          label: "Experience",
          value: experience.isEmpty ? "Not available" : "$experience Years",
        ),
        _infoTile(
          icon: Icons.medical_services_outlined,
          label: "Specialization",
          value: specilization.isEmpty ? "Not available" : specilization,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.35),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cyanAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_outlined, color: Color(0xff38BDF8), size: 20),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Proof Tile ────────────────────────────────────────────
  Widget _buildProofTile() {
    return GestureDetector(
      onTap: handleProofPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _emeraldAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.file_present_rounded,
                  color: Color(0xff34D399), size: 20),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Proof Document",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    proof.isEmpty
                        ? "No document uploaded"
                        : "Tap to view document",
                    style: TextStyle(
                      color: proof.isEmpty
                          ? Colors.white.withOpacity(0.5)
                          : const Color(0xff34D399),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              proof.isEmpty
                  ? Icons.info_outline_rounded
                  : Icons.open_in_new_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: "Edit Profile",
            icon: Icons.edit_rounded,
            outlined: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Editprofile()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: "Change Password",
            icon: Icons.lock_outline_rounded,
            outlined: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Changepassword()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool outlined,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: outlined ? Colors.white.withOpacity(0.05) : null,
          gradient: outlined
              ? null
              : const LinearGradient(colors: [_cyanAccent, _emeraldAccent]),
          borderRadius: BorderRadius.circular(20),
          border: outlined
              ? Border.all(color: Colors.white.withOpacity(0.14), width: 1.5)
              : null,
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: _cyanAccent.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
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