import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/patient_histo.dart';
import 'package:flutter/material.dart';

class New extends StatefulWidget {
  const New({super.key});

  @override
  State<New> createState() => _NewState();
}

class _NewState extends State<New> {
  List<Map<String, dynamic>> allPatients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();

    searchController.addListener(() {
      filterPatients(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPatients() async {
    try {
      setState(() {
        isLoading = true;
      });

      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final appointments = await supabase
          .from('tbl_appoinment')
          .select()
          .eq('dermatologist_id', currentUser.id);

      List<Map<String, dynamic>> uniquePatients = [];
      Set<String> seenUsers = {};

      for (var appointment in appointments) {
        final userId = appointment['user_id'];
        if (userId == null) continue;

        try {
          final user = await supabase.from('tbl_user').select('''
                    user_name,
                    user_photo,
                    user_contact,
                    user_email
                  ''').eq('user_id', userId).single();

          final patient = {
            'user_name': user['user_name'],
            'user_email': user['user_email'],
            'user_contact': user['user_contact'],
            'user_photo': user['user_photo'],
            'booking_date': appointment['appoinment_date']?.toString(),
            'booking_time': appointment['appoinment_time']?.toString(),
          };

          debugPrint("PATIENT DATA: $patient");

          final uniqueKey = patient['user_email']?.toString() ??
              patient['user_contact']?.toString() ??
              '';

          if (uniqueKey.isNotEmpty && !seenUsers.contains(uniqueKey)) {
            seenUsers.add(uniqueKey);
            uniquePatients.add(patient);
          }
        } catch (e) {
          debugPrint("User fetch error: $e");
        }
      }

      if (!mounted) return;

      setState(() {
        allPatients = uniquePatients;
        filteredPatients = uniquePatients;
        isLoading = false;
      });

      debugPrint("Patients Loaded: $filteredPatients");
    } catch (e) {
      debugPrint("Fetch error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterPatients(String query) {
    final filtered = allPatients.where((patient) {
      final name = patient['user_name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredPatients = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xff060D12), // Synced Deep Dark Layout Background
      appBar: AppBar(
        backgroundColor: const Color(0xff060D12),
        elevation: 0,
        centerTitle: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2331),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        title: const Text(
          "My Patients",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Search Module Layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C2331),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: "Search clinical records...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.32),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color:
                        Color(0xff38BDF8), // Dynamic Platform Accent Cyan Icon
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0EA5E9),
                    ),
                  )
                : filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          "No Operational Patient Records Found",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.32),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          final name = patient['user_name'] ?? "Unknown";
                          final email =
                              patient['user_email'] ?? "No Email Managed";
                          final phone =
                              patient['user_contact'] ?? "No Primary Contact";
                          final photo = patient['user_photo'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF1C2331), // Matched Surface Layout Color
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar wrapped in custom Gradient Chip ring
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff0EA5E9),
                                        Color(0xff10B981)
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xff060D12),
                                    backgroundImage:
                                        photo != null && photo.isNotEmpty
                                            ? NetworkImage(photo)
                                            : null,
                                    child: photo == null || photo.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color:
                                                Colors.white.withOpacity(0.50),
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.50),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.32),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Custom action button matching Welcome Glass layout view elements
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PatientHisto(
                                            patient: patient,
                                            bookingDate: patient['booking_date']
                                                    ?.toString() ??
                                                "Not Available",
                                            bookingTime: patient['booking_time']
                                                    ?.toString() ??
                                                "Not Available",
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(
                                          0xff38BDF8), // Electric blue accent arrow pointer
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
