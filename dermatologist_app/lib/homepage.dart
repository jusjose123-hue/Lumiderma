import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/myprofile.dart';
import 'package:dermatologist_app/new.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomeScreen(),
      // const PlaceholderPage(
      //   title: "Schedule Feed",
      //   icon: Icons.calendar_month,
      // ),
      const New(),
      const Myprofile(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff060D12),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xff060D12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          enableFeedback: false,
          selectedItemColor: const Color(0xff0EA5E9),
          unselectedItemColor: Colors.white.withOpacity(0.32),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.event_note_rounded),
            //   label: 'Schedule',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String? name;
  String? photo;

  /// FETCH DERMATOLOGIST DETAILS
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
        name = response['dermatologist_name'] ?? "";
        photo = response['dermatologist_photo'] ?? "";
      });
    } catch (e) {
      debugPrint("Error fetching dermatologist: $e");
    }
  }

  /// FETCH APPOINTMENTS
  Future<void> fetchAppointments() async {
    try {
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint("No logged in user");
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('tbl_appoinment')
          .select('''
          *,
          tbl_user (
            user_name,
            user_photo,
            user_contact,
            user_email
          )
        ''')
          .eq('dermatologist_id', currentUser.id)
          .order('appoinment_date', ascending: false);

      debugPrint("Appointments Response: $response");

      if (!mounted) return;

      setState(() {
        appointments = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  /// HANDLER FOR PULL-TO-REFRESH
  Future<void> _handleRefresh() async {
    await Future.wait([
      fetchdermatologist(),
      fetchAppointments(),
    ]);
  }

  /// UPDATE STATUS
  Future<void> _updateStatus(String appointmentId, String status) async {
    try {
      await supabase.from('tbl_appoinment').update({
        'appoinment_status': status.toUpperCase(),
      }).eq('appoinment_id', appointmentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appointment $status successfully"),
          backgroundColor: const Color(0xff10B981),
        ),
      );

      fetchAppointments();
    } catch (e) {
      debugPrint("Update Error: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchdermatologist();
      fetchAppointments();
    });
  }

  Widget _buildAppointmentList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(50.0),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xff0EA5E9),
          ),
        ),
      );
    }

    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50.0),
        child: Center(
          child: Text(
            "No appointments found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.32),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      itemCount: appointments.length,
      itemBuilder: (context, index) =>
          _buildAppointmentCard(appointments[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live Counts synced safely with .trim() and .toUpperCase()
    final pendingCount = appointments.where((e) {
      return (e['appoinment_status'] ?? "").toString().trim().toUpperCase() ==
          "PENDING";
    }).length;

    final doneCount = appointments.where((e) {
      final status =
          (e['appoinment_status'] ?? "").toString().trim().toUpperCase();
      return status == "DONE" || status == "APPROVED";
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xff060D12),
      body: RefreshIndicator(
        color: const Color(0xff0EA5E9),
        backgroundColor: const Color(0xFF1C2331),
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${name ?? "Doctor"} 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    /// PROFILE IMAGE WITH SHADOW GRADIENT CHIP EFFECT
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0EA5E9).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF1C2331),
                        backgroundImage: photo != null && photo!.isNotEmpty
                            ? NetworkImage(photo!)
                            : null,
                        child: photo == null || photo!.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// NOTIFICATION CARD (MATCHING DISCREET SMART PLATFORM BADGE)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xff0EA5E9).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xff0EA5E9).withOpacity(0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xff38BDF8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You have $pendingCount pending operational requests",
                          style: const TextStyle(
                            color: Color(0xff38BDF8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// STATS STRIP
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 38),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      statCard(appointments.length.toString(), "Total Ops",
                          const Color(0xff0EA5E9)),
                      _customDivider(),
                      statCard(pendingCount.toString(), "Pending",
                          const Color(0xff6366F1)),
                      _customDivider(),
                      statCard(doneCount.toString(), "Completed",
                          const Color(0xff10B981)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Container(
                //   padding: const EdgeInsets.all(22),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(24),
                //     gradient: const LinearGradient(
                //       colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //     boxShadow: [
                //       BoxShadow(
                //         color: const Color(0xff0EA5E9).withOpacity(0.35),
                //         blurRadius: 20,
                //         offset: const Offset(0, 8),
                //       ),
                //     ],
                //   ),
                //   child: const Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             "Total Revenue generated",
                //             style: TextStyle(
                //               color: Colors.white70,
                //               fontSize: 12,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //           SizedBox(height: 4),
                //           Text(
                //             "₹1500",
                //             style: TextStyle(
                //               fontSize: 26,
                //               fontWeight: FontWeight.w800,
                //               color: Colors.white,
                //               letterSpacing: -0.5,
                //             ),
                //           ),
                //         ],
                //       ),
                //       Text(
                //         "✦",
                //         style: TextStyle(fontSize: 24, color: Colors.white70),
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 36),

                /// TITLE & SEPARATOR LINE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Consultations",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 45,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// APPOINTMENT LIST
                _buildAppointmentList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// VERTICAL DIVIDER UTILITY
  Widget _customDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withOpacity(0.10),
      );

  /// STYLISH MINIMALIST STAT ITEM
  Widget statCard(String value, String label, Color accentColor) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.6)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.42),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// APPOINTMENT CARD (UPDATED WITH PATIENTHISTO SLATE DESIGN)
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final user = appointment['tbl_user'] ?? {};
    String patientName = user['user_name'] ?? "Unknown Patient";
    String? photoUrl = user['user_photo'];
    String status = (appointment['appoinment_status'] ?? "PENDING")
        .toString()
        .trim()
        .toUpperCase();
    String date = appointment['appoinment_date']?.toString() ?? "";
    String time = appointment['appoinment_time']?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF1C2331), // Synced backdrop matching details popup
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.06),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Icon(
                        Icons.person,
                        color: Colors.white.withOpacity(0.50),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$date · $time",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user['user_email'] ?? "",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),

          // GLASS-NEOMORPHIC ACTION BUTTON MODULE FOR PENDING STATES
          if (status == 'PENDING') ...[
            const SizedBox(height: 18),
            Row(
              children: [
                // REJECT ACTION
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(
                      appointment['appoinment_id'].toString(),
                      'REJECTED',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.redAccent.withOpacity(0.06),
                    ),
                    child: const Text(
                      "Decline",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ACCEPT ACTION
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => _updateStatus(
                        appointment['appoinment_id'].toString(),
                        'APPROVED',
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Accept",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// BADGE RENDER HANDLER WITH CORRECT MATRIX SCHEME
  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: getStatusColor(status).withOpacity(0.40)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// PLACEHOLDER PAGE
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff060D12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 70,
              color: Colors.white.withOpacity(0.08),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// STATUS PALETTE ADJUSTED WITH THE HIGHLIGHT SPECIFICS OF YOUR WELLCOME VIEW
Color getStatusColor(String status) {
  final value = status.toString().trim().toUpperCase();
  switch (value) {
    case "APPROVED":
    case "DONE":
      return const Color(0xff10B981); // Emerald Green Accent
    case "PENDING":
      return const Color(0xff6366F1); // Support Indigo Highlight Accent
    case "REJECTED":
      return Colors.redAccent;
    default:
      return const Color(0xff0EA5E9); // Cyan Default Accent
  }
}
