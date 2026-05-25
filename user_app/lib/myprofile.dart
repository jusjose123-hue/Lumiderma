import 'package:admin_app/changepassword.dart';
import 'package:admin_app/complaint.dart';
import 'package:admin_app/editprofile.dart';
import 'package:admin_app/index_page.dart';

import 'package:admin_app/main.dart';
import 'package:admin_app/my_complaint.dart';
import 'package:admin_app/orders.dart';
import 'package:admin_app/welcompage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});

  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile>
    with SingleTickerProviderStateMixin {
  String name = '';
  String email = '';
  String address = '';
  String photo = '';
  String gender = '';
  String contact = '';
  String typeName = '';

  bool isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palette: Synchronized Ecosystem Dark Ritual Identity ──
  static const Color _bg = Color(0xff0D0A14);
  static const Color _surface = Color(0xff161124);
  static const Color _surfaceAlt = Color(0xff1A142A);
  static const Color _accentPurple = Color(0xffA855F7);
  static const Color _accentPink = Color(0xffEC4899);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xff9CA3AF);
  static const Color _border = Color(0xff2A1F3D);
  static const Color _error = Color(0xffEF4444);

  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_accentPurple, _accentPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    fetchuser();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchuser() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      final response = await supabase
          .from('tbl_user')
          .select('*, tbl_type(type_name)')
          .eq('user_id', user!.id)
          .single();

      if (!mounted) return;
      setState(() {
        name = response['user_name'] ?? '';
        email = response['user_email'] ?? '';
        address = response['user_address'] ?? '';
        gender = response['user_gender'] ?? '';
        contact = response['user_contact'] ?? '';
        typeName = response['tbl_type']?['type_name'] ?? '';
        photo = response['user_photo'] ?? '';
        isLoading = false;
      });

      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Error fetching user: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _accentPurple,
                  strokeWidth: 2,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: RefreshIndicator(
                    color: _accentPurple,
                    backgroundColor: _surface,
                    onRefresh: fetchuser,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildAppBar(context),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildHeroCard(),
                              const SizedBox(height: 24),
                              _buildInfoSection(),
                              const SizedBox(height: 24),
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
    );
  }

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: IconButton(
            onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IndexPage()),
      ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 14,
            ),
          ),
        ),
      ),
      title: Text(
        "My Profile",
        style: GoogleFonts.outfit(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: _textSecondary),
          color: _surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border),
          ),
          elevation: 8,
          onSelected: (value) async {
            if (value == 'help') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Complaint()),
              );
            } else if (value == 'complaints') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyComplaintsPage()),
              );
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
            _menuItem(
              Icons.help_outline_rounded,
              'help',
              "Help Center",
              _textPrimary,
            ),
            _menuItem(
              Icons.inbox_outlined,
              'complaints',
              "My Complaints",
              _textPrimary,
            ),
            const PopupMenuDivider(color: _border),
            _menuItem(Icons.logout_rounded, 'signout', "Sign Out", _error),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentPurple.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _brandGradient,
              boxShadow: [
                BoxShadow(
                  color: _accentPurple.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: _surfaceAlt,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: _textSecondary,
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            name.isEmpty ? '—' : name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email.isEmpty ? '—' : email,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: _textSecondary, fontSize: 14),
          ),

          if (typeName.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accentPink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _accentPink.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_rounded, size: 13, color: _accentPink),
                  const SizedBox(width: 6),
                  Text(
                    typeName,
                    style: GoogleFonts.outfit(
                      color: _accentPink,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip(
                Icons.location_on_outlined,
                address.isEmpty ? '—' : _truncate(address, 12),
              ),
              _verticalDivider(),
              _statChip(Icons.wc_rounded, gender.isEmpty ? '—' : gender),
              _verticalDivider(),
              _statChip(
                Icons.phone_outlined,
                contact.isEmpty ? '—' : _truncate(contact, 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: _accentPurple, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: _textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 36, color: _border);
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  // ── Info Section ──────────────────────────────────────────
  Widget _buildInfoSection() {
    final tiles = [
      _TileData(Icons.location_on_outlined, "Address", address, _accentPink),
      _TileData(Icons.wc_rounded, "Gender", gender, _accentPurple),
      _TileData(
        Icons.phone_outlined,
        "Contact",
        contact,
        const Color(0xff6366F1),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final t = tiles[i];
          return _infoTile(
            icon: t.icon,
            label: t.label,
            value: t.value.isEmpty ? "Not provided" : t.value,
            accentColor: t.color,
            showDivider: i < tiles.length - 1,
          );
        }),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: _border, indent: 20, endIndent: 20),
      ],
    );
  }

  // ── Action Buttons (Redesigned with Brand Gradient Fill Elements) ──
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                label: "Edit Profile",
                icon: Icons.edit_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Editprofile()),
                  );
                  fetchuser();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                label: "Reset Password",
                icon: Icons.lock_outline_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Changepassword()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _actionButton(
          label: "Order History",
          icon: Icons.receipt_long_rounded,
          fullWidth: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyOrdersPage()),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _brandGradient, // High fidelity premium filling colors
          boxShadow: [
            BoxShadow(
              color: _accentPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TileData(this.icon, this.label, this.value, this.color);
}
