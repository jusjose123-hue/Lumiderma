import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentManagement extends StatefulWidget {
  const AppointmentManagement({super.key});

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchAndSubscribe();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  /// 1. Fetch User's Appointments joined with Doctor (Dermatologist) Details
  Future<void> _fetchAndSubscribe() async {
    await _loadAppointmentsData();

    // Listen to live database changes so status updates reflect instantly
    _realtimeChannel = supabase
        .channel('public:tbl_appoinment')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tbl_appoinment',
          callback: (payload) {
            _loadAppointmentsData();
          },
        );

    _realtimeChannel!.subscribe();
  }

  /// 2. Core Fetch Logic pulling Doctor information instead of Patient information
  Future<void> _loadAppointmentsData() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = "Not authenticated";
        });
        return;
      }

      // Changed the join from tbl_user to tbl_dermatologist to pull doctor details
      final response = await supabase
          .from('tbl_appoinment')
          .select('''
            appoinment_id,
            appoinment_date,
            appoinment_status,
            appoinment_time,
            user_id,
            dermatologist_id,
            tbl_dermatologist (
              dermatologist_name,
              dermatologist_photo
            )
          ''')
          .eq(
            'user_id',
            currentUser.id,
          ) // Filters to only show this logged-in user's appointments
          .order('appoinment_date', ascending: false);

      if (!mounted) return;

      setState(() {
        _allAppointments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint("User Appointments Load Error: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            "My Appointments",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Color(0xffEC4899),
            indicatorWeight: 3,
            labelColor: Color(0xffEC4899),
            unselectedLabelColor: Colors.white24,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                text: "PENDING",
                icon: Icon(Icons.hourglass_empty_rounded, size: 20),
              ),
              Tab(
                text: "BOOKED",
                icon: Icon(Icons.check_circle_outline_rounded, size: 20),
              ),
              Tab(
                text: "REJECTED",
                icon: Icon(Icons.cancel_outlined, size: 20),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
            : _errorMessage != null
            ? Center(
                child: Text(
                  "Error: $_errorMessage",
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            : TabBarView(
                children: [
                  _buildAppointmentFilteredList('PENDING'),
                  _buildAppointmentFilteredList('APPROVED'),
                  _buildAppointmentFilteredList('REJECTED'),
                ],
              ),
      ),
    );
  }

  Widget _buildAppointmentFilteredList(String statusFilter) {
    final filteredList = _allAppointments.where((item) {
      final dbStatus = (item['appoinment_status'] ?? "")
          .toString()
          .trim()
          .toUpperCase();

      if (statusFilter == 'APPROVED') {
        return dbStatus == 'APPROVED' || dbStatus == 'DONE';
      }
      return dbStatus == statusFilter;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          "No appointments here",
          style: const TextStyle(color: Colors.white24, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final appointment = filteredList[index];
        final doctor = appointment['tbl_dermatologist'] ?? {};
        return _buildDoctorRecordCard(appointment, doctor);
      },
    );
  }

  Widget _buildDoctorRecordCard(
    Map<String, dynamic> appointment,
    Map<String, dynamic> doctor,
  ) {
    // Read Doctor fields from the relation payload
    final String doctorName =
        doctor['dermatologist_name'] ?? "Dermatologist Expert";
    final String? photoUrl = doctor['dermatologist_photo'];
    final String dbStatus = (appointment['appoinment_status'] ?? "")
        .toString()
        .trim()
        .toUpperCase();

    String displayStatus = "Pending";
    Color badgeColor = Colors.orange;

    if (dbStatus == 'APPROVED' || dbStatus == 'DONE') {
      displayStatus = "Booked";
      badgeColor = Colors.green;
    } else if (dbStatus == 'REJECTED') {
      displayStatus = "Rejected";
      badgeColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:Color(0xff0D0A14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Doctor Image Layout Profile Badge
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.black,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person_pin_rounded, color: Colors.white24)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${appointment['appoinment_date'] ?? ''} | ${appointment['appoinment_time'] ?? ''}",
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // Pure display Status Label Badge Component
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              displayStatus,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
