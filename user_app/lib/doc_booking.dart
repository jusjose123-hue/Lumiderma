import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DocBooking extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DocBooking({super.key, required this.doctor});

  @override
  State<DocBooking> createState() => _DocBookingState();
}

class _DocBookingState extends State<DocBooking>
    with SingleTickerProviderStateMixin {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palette ───────────────────────────────────────────────
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surfaceAlt = Color(0xFF1C2333);
  static const _accent = Color(0xFFD4A5A5);
  static const _accentDim = Color(0xFFB07070);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _success = Color(0xFF3FB950);
  static const _error = Color(0xFFF85149);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────
  Future<void> _handleBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      _showSnack("Please select both date and time", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      await supabase.from('tbl_appoinment').insert({
        'appoinment_date': formattedDate,
        'appoinment_time': formattedTime,
        'appoinment_status': 'pending',
        'user_id': supabase.auth.currentUser?.id,
        'dermatologist_id': widget.doctor['dermatologist_id'],
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      debugPrint("Insert Error: $e");
      if (mounted) {
        _showSnack("Booking failed. Please try again.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(data: _darkPickerTheme(), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        dateController.text = DateFormat('EEEE, MMM d, yyyy').format(picked);

        // Clear selected time if it conflicts with the new date context
        if (_selectedTime != null) {
          if (_isPastTime(_selectedTime!, picked)) {
            _selectedTime = null;
            timeController.clear();
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_selectedDate == null) {
      _showSnack("Please select a date first", isError: true);
      return;
    }

    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(data: _darkPickerTheme(), child: child!),
    );

    if (picked != null) {
      // Check if the selected time is in the past for today's date
      if (_isPastTime(picked, _selectedDate!)) {
        _showSnack(
          "Cannot choose a time slot that has already passed",
          isError: true,
        );
        return;
      }

      setState(() {
        _selectedTime = picked;
        timeController.text = picked.format(context);
      });
    }
  }

  // Helper function to check if chosen time is in the past
  bool _isPastTime(TimeOfDay pickedTime, DateTime date) {
    final now = DateTime.now();

    // Only check time boundaries if the selected date is today
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      if (pickedTime.hour < now.hour) {
        return true;
      } else if (pickedTime.hour == now.hour &&
          pickedTime.minute < now.minute) {
        return true;
      }
    }
    return false;
  }

  ThemeData _darkPickerTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        onPrimary: _bg,
        surface: _surface,
        onSurface: _textPrimary,
      ),
      dialogBackgroundColor: _surfaceAlt,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? _error : _success,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success.withOpacity(0.12),
                  border: Border.all(
                    color: _success.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _success,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Booking Confirmed!",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your appointment has been successfully scheduled. You can view details in your appointments list.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.withOpacity(0.15),
                    foregroundColor: _accent,
                    elevation: 0,
                    side: const BorderSide(color: _accent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorName =
        widget.doctor['dermatologist_name'] ??
        widget.doctor['doctor_name'] ??
        'Dermatologist';

    final doctorPhoto = widget.doctor['dermatologist_photo'] ?? '';
    final doctorSpec =
        widget.doctor['dermatologist_specilization'] ?? 'Dermatology';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: _bg,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                // Rest of the UI remains unchanged...
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDoctorCard(doctorName, doctorPhoto, doctorSpec),
                      const SizedBox(height: 24),
                      _buildBookingCard(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(String name, String photo, String spec) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accentDim.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accent, _accentDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: _surfaceAlt,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: _textSecondary,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. $name",
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: _accent),
                      SizedBox(width: 5),
                      Text(
                        "Available",
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SELECT DATE & TIME",
            style: TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          _buildPickerField(
            controller: dateController,
            hint: "Choose a date",
            icon: Icons.calendar_today_rounded,
            onTap: () => _selectDate(context),
            hasValue: _selectedDate != null,
          ),
          const SizedBox(height: 14),
          _buildPickerField(
            controller: timeController,
            hint: "Choose a time",
            icon: Icons.access_time_rounded,
            onTap: () => _selectTime(context),
            hasValue: _selectedTime != null,
          ),
          const SizedBox(height: 12),
          if (_selectedDate != null && _selectedTime != null)
            _buildSummaryStrip(),
          const SizedBox(height: 28),
          Divider(height: 1, color: _border),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent.withOpacity(0.15),
                disabledBackgroundColor: _surfaceAlt,
                elevation: 0,
                side: BorderSide(
                  color: _isLoading ? _border : _accent.withOpacity(0.50),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accent,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18, color: _accent),
                        SizedBox(width: 8),
                        Text(
                          "Confirm Booking",
                          style: TextStyle(
                            color: _accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? _accent.withOpacity(0.40) : _border,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? _accent : _textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  color: controller.text.isEmpty
                      ? _textSecondary
                      : _textPrimary,
                  fontSize: 14,
                  fontWeight: controller.text.isEmpty
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${DateFormat('MMM d, yyyy').format(_selectedDate!)}  ·  ${_selectedTime!.format(context)}",
              style: const TextStyle(
                color: _accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
