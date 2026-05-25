import 'dart:async';
import 'package:flutter/material.dart';
import 'package:admin_app/main.dart'; // Ensure this contains your supabase instance
import 'package:google_fonts/google_fonts.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  // Cohesive visual theme tokens matching the ecosystem aesthetic
  static const Color bgDark = Color(0xff0D0A14);
  static const Color cardColor = Color(0xff161124);
  static const Color borderSubtle = Color(0xff2A1F3D);
  static const Color accentPurple = Color(0xffA855F7);
  static const Color accentPink = Color(0xffEC4899);
  static const Color textSecondary = Color(0xff9CA3AF);

  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('tbl_complaint')
          .select('*')
          .eq('user_id', userId)
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
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgDark,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderSubtle),
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
        title: Text(
          "My Complaints",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: accentPurple,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchComplaints,
              color: accentPurple,
              backgroundColor: cardColor,
              child: complaints.isEmpty
                  ? Center(
                      child: Text(
                        "No Complaints Found",
                        style: GoogleFonts.outfit(
                          color: textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
    Color statusColor = isResolved
        ? const Color(0xff00D4AA)
        : const Color(0xffEC4899);
    String statusText = isResolved ? "Resolved" : "Under Review";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xff161124),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xff2A1F3D), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket ID and Status Badge Layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ticket #$id",
                  style: GoogleFonts.outfit(
                    color: const Color(0xff6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Complaint Header & Content Block Description
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.outfit(
                color: const Color(0xff9CA3AF),
                height: 1.4,
                fontSize: 13.5,
              ),
            ),

            // Complaint Image Display Network Section
            if (photo != null && photo!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photo!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: const Color(0xff120E1C),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xffA855F7),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xff120E1C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xff2A1F3D)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image_rounded,
                          color: Color(0xff6B7280),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Image unavailable",
                          style: GoogleFonts.outfit(
                            color: const Color(0xff6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Support Center Backoffice Response Bubble Box
            if (reply != null && reply!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1A142A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xff00D4AA).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 16,
                          color: Color(0xff00D4AA),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Response from Support",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff00D4AA),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reply!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xffE8EDF4),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(color: Color(0xff2A1F3D), height: 1),
            const SizedBox(height: 14),

            // Metadata Row Area: Time details + Pipeline Tracking Status Elements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xff6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date.contains('T') ? date.split('T')[0] : date,
                      style: GoogleFonts.outfit(
                        color: const Color(0xff6B7280),
                        fontSize: 12,
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
        color: active ? const Color(0xffA855F7) : const Color(0xff2A1F3D),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xffA855F7).withOpacity(0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      width: 24,
      height: 2,
      color: active ? const Color(0xffA855F7) : const Color(0xff2A1F3D),
    );
  }
}
