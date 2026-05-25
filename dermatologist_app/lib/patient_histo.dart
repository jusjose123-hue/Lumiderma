import 'package:flutter/material.dart';

class PatientHisto extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String bookingDate;
  final String bookingTime;

  const PatientHisto({
    super.key,
    required this.patient,
    required this.bookingDate,
    required this.bookingTime,
  });

  @override
  State<PatientHisto> createState() => _PatientHistoState();
}

class _PatientHistoState extends State<PatientHisto> {
  String formatBookingDate(String? dateString) {
    try {
      if (dateString == null || dateString.isEmpty) {
        return "Not Available";
      }

      final date = DateTime.parse(dateString);

      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Not Available";
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final String name = patient['user_name']?.toString() ?? "Unknown Patient";
    final String email = patient['user_email']?.toString() ?? "No Email";
    final String phone = patient['user_contact']?.toString() ?? "No Contact";
    final String? photo = patient['user_photo']?.toString();

    return Scaffold(
      backgroundColor:
          const Color(0xff060D12), // Matching Deep Dark Theme Background
      appBar: AppBar(
        backgroundColor: const Color(0xff060D12),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Patient Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Card (Glassmorphic Container Styling)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(
                    0xFF1C2331), // Synced Slate Container Background
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: email,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff0EA5E9), Color(0xff10B981)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0EA5E9).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xff060D12),
                        backgroundImage: photo != null && photo.isNotEmpty
                            ? NetworkImage(photo)
                            : null,
                        child: photo == null || photo.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white.withOpacity(0.50),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Cyan Platform Badge Accent
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff0EA5E9).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xff0EA5E9).withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      "✦  Registered Patient",
                      style: TextStyle(
                        color: Color(0xff38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Card
            _buildCard(
              title: "Contact Information",
              children: [
                _buildTile(
                  Icons.email_outlined,
                  "Email Address",
                  email,
                ),
                _buildTile(
                  Icons.phone_outlined,
                  "Mobile Number",
                  phone,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Booking Card
            _buildCard(
              title: "Appointment Info",
              children: [
                _buildTile(
                  Icons.calendar_month_rounded,
                  "Scheduled Date",
                  formatBookingDate(widget.bookingDate),
                ),
                _buildTile(
                  Icons.access_time_rounded,
                  "Scheduled Time",
                  widget.bookingTime,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2331),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          // Short Accent Line Under Section Title
          Container(
            width: 25,
            height: 2.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Color(0xff0EA5E9), Color(0xff10B981)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xff38BDF8), // Synced Icon Accent Highlight
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
