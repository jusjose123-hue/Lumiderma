import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:userapp/reply.dart';

class ViewComplaints extends StatefulWidget {
  const ViewComplaints({super.key});

  @override
  State<ViewComplaints> createState() => _ViewComplaintsState();
}

class _ViewComplaintsState extends State<ViewComplaints> {
 static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color accentColor = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  late Future<List<Map<String, dynamic>>> _complaintsFuture;
  bool _ascending = false; // Track sort state

  @override
  void initState() {
    super.initState();
    _refreshComplaints();
  }

  void _refreshComplaints() {
    setState(() {
      _complaintsFuture = _fetchComplaints();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchComplaints() async {
    // Fetches fresh data based on the chosen sort order
    final data = await Supabase.instance.client
        .from('tbl_complaint')
        .select('*, tbl_user(user_name), tbl_dermatologist(dermatologist_name)')
        .order('complaint_date', ascending: _ascending);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _openScreenshot(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Management Console",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _ascending = !_ascending; // Toggle sorting order
              _refreshComplaints(); // Re-run query
            },
            icon: Icon(
              _ascending ? Icons.sort_by_alpha : Icons.sort,
              color: accentColor,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 1,
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("System Error", style: TextStyle(color: accentColor)),
            );
          }

          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const Center(
              child: Text(
                "No complaints found.",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) =>
                _buildModernRecord(complaints[index]),
          );
        },
      ),
    );
  }

  Widget _buildModernRecord(Map<String, dynamic> item) {
    final String status = item['complaint_status'] ?? 'Pending';
    final bool isPending = status.toLowerCase() == 'pending';
    final String? screenshotUrl = item['complaint_ss'];

    // Determine issuer (User or Dermatologist fallback)
    final String issuerName =
        item['tbl_user']?['user_name'] ??
        item['tbl_dermatologist']?['dermatologist_name'] ??
        'UNKNOWN';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: const Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Data Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "REF: #${item['complaint_id'] ?? 'N/A'}".toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['complaint_date'] != null
                          ? item['complaint_date'].toString().split('T')[0]
                          : 'No Date',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title & User
                Text(
                  item['complaint_title']?.toUpperCase() ?? 'UNTITLED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "BY: $issuerName",
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white, thickness: 1),
                ),
                // The Content Body
                Text(
                  item['complaint_content'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Control Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFF181818)),
            child: Row(
              children: [
                _indicator(
                  isPending ? "ACTION REQUIRED" : "RESOLVED",
                  isPending,
                ),
                const Spacer(),
                if (screenshotUrl != null && screenshotUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.collections_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () => _openScreenshot(screenshotUrl),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Reply(
                          complaintId: (item['complaint_id'] ?? '').toString(),
                          userId: (item['user_id'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    "REPLY",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator(String label, bool isPending) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPending ? const Color.fromARGB(255, 246, 92, 92) : Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isPending ? const Color.fromARGB(255, 205, 15, 15) : Colors.green,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
