import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:userapp/main.dart';

class Userlist extends StatefulWidget {
  const Userlist({super.key});

  @override
  State<Userlist> createState() => _UserlistState();
}

class _UserlistState extends State<Userlist> {
  // Global Color scheme matched perfectly with Place.dart
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color accentColor = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  List<Map<String, dynamic>> _user = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchuser();
  }

  Future<void> fetchuser() async {
    try {
      setState(() => _isLoading = true);

      // ✅ FIXED TABLE NAME
      final response = await supabase.from('tbl_user').select();

      debugPrint("Fetched data: $response");

      setState(() {
        _user = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateStatus(dynamic id, String status) async {
    try {
      await supabase
          .from('tbl_user')
          .update({'user_status': status})
          .eq('user_id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as ${status.toUpperCase()}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      fetchuser(); // refresh list
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _user
        .where((d) => d['user_status'] == null || d['user_status'] == 'pending')
        .toList();

    final approvedList = _user
        .where((d) => d['user_status'] == 'approved')
        .toList();

    final rejectedList = _user
        .where((d) => d['user_status'] == 'rejected')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TabBar(
                isScrollable: true,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: subTextColor,
                tabs: const [
                  Tab(text: "PENDING"),
                  Tab(text: "APPROVED"),
                  Tab(text: "REJECTED"),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : TabBarView(
                      children: [
                        _buildTableContainer(pendingList, "pending"),
                        _buildTableContainer(approvedList, "approved"),
                        _buildTableContainer(rejectedList, "rejected"),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No $type user found.",
          style: const TextStyle(color: subTextColor, fontSize: 16),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: _buildDataTable(data),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text(
          "User Panel",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> list) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.white.withOpacity(0.05),
          ),
          columns: const [
            DataColumn(
              label: Text(
                "SL.NO",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "PHOTO",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "NAME",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "EMAIL",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "CONTACT",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "GENDER",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "ACTIONS",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: list.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final user = entry.value;
            final status = user['user_status'];

            return DataRow(
              cells: [
                DataCell(
                  Text("$index", style: const TextStyle(color: subTextColor)),
                ),

                DataCell(
                  CircleAvatar(
                    backgroundImage:
                        (user['user_photo'] != null &&
                            user['user_photo'].toString().isNotEmpty)
                        ? NetworkImage(user['user_photo'])
                        : null,
                    child: user['user_photo'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),

                DataCell(
                  Text(
                    user['user_name'] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                DataCell(
                  Text(
                    user['user_email'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                DataCell(
                  Text(
                    user['user_contact'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                DataCell(
                  Text(
                    user['user_gender'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                DataCell(
                  Row(
                    children: [
                      if (status != 'approved')
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.greenAccent,
                          ),
                          onPressed: () =>
                              updateStatus(user['user_id'], 'approved'),
                        ),
                      if (status != 'rejected')
                        IconButton(
                          icon: const Icon(
                            Icons.highlight_off,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              updateStatus(user['user_id'], 'rejected'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
