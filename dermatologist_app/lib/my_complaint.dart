import 'dart:async';
import 'package:dermatologist_app/main.dart';
import 'package:flutter/material.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;

  // ── Theme Sync Palette ──────────────────────────────────────────
  static const _bg = Color(0xff060D12);
  static const _cyanAccent = Color(0xff0EA5E9);
  static const _emeraldAccent = Color(0xff10B981);

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final dermatologistId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('tbl_complaint')
          .select('*')
          .eq('dermatologist_id', dermatologistId)
          .order('complaint_id', ascending: false);

      setState(() {
        complaints = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("COMPLAINT ERROR : $e");
      setState(() => isLoading = false);
    }
  }

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
            top: size.height * 0.45,
            left: -90,
            child: _GlowBlob(
                size: 280, color: const Color(0xff6366F1), opacity: 0.12),
          ),
          Positioned(
            bottom: -100,
            right: -40,
            child: _GlowBlob(size: 300, color: _emeraldAccent, opacity: 0.12),
          ),

          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildAppBar(context),
              ],
              body: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _cyanAccent))
                  : RefreshIndicator(
                      color: _cyanAccent,
                      backgroundColor: const Color(0xff0F172A),
                      onRefresh: fetchComplaints,
                      child: complaints.isEmpty
                          ? Center(
                              child: Text(
                                "No Complaints Found",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              itemCount: complaints.length,
                              itemBuilder: (context, index) {
                                final item = complaints[index];
                                return ComplaintItem(
                                  title: item['complaint_title'] ?? 'No Title',
                                  description: item['complaint_content'] ?? '',
                                  date: item['complaint_date'] ?? '',
                                  reply: item['complaint_reply'],
                                  status: item['complaint_status'] ?? 'pending',
                                  id: item['complaint_id'].toString(),
                                  photo: item['complaint_photo'],
                                );
                              },
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

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
        "My Complaints",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }
}

class ComplaintItem extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String? reply;
  final String status;
  final String id;
  final String? photo;

  const ComplaintItem({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    this.reply,
    required this.status,
    required this.id,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    bool isResolved =
        status.toLowerCase() == 'replied' || status.toLowerCase() == 'closed';
    Color statusColor =
        isResolved ? const Color(0xff10B981) : const Color(0xffF59E0B);
    String statusText = isResolved ? "Resolved" : "Under Review";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket ID and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ticket #$id",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: statusColor.withOpacity(0.30)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title and Description
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),

            // --- COMPLAINT PHOTO ---
            if (photo != null && photo!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    photo!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.white.withOpacity(0.02),
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xff0EA5E9)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 4),
                          Text(
                            "Image unavailable",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Admin Reply Section
            if (reply != null && reply!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xff10B981).withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                          color: Color(0xff34D399),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Response from Support",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xff34D399),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reply!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 14),

            // Date and Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date.contains('T') ? date.split('T')[0] : date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStep(true),
                    _buildLine(isResolved),
                    _buildStep(isResolved),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            active ? const Color(0xff0EA5E9) : Colors.white.withOpacity(0.15),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xff0EA5E9).withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      width: 24,
      height: 2,
      color: active ? const Color(0xff0EA5E9) : Colors.white.withOpacity(0.15),
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
