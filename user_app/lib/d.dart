import 'package:admin_app/docdetail.dart';
import 'package:admin_app/index_page.dart';
import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class _T {
  static const bg = Color(0xff0D0A14);

  static const surface = Color(0xff120E1C);
  static const card = Color(0xff161124);
  static const cardAlt = Color(0xff1A142A);

  static const border = Color(0xff2A1F3D);

  static const indigo = Color(0xffA855F7); // Purple accent
  static const indigoDim = Color(0xff7C3AED); // Deeper purple
  static const indigoGlow = Color(0x33A855F7); // Translucent purple glow
  static const blue = Color(0xff6366F1); // Indigo-blue feature accent
  static const teal = Color(
    0xffEC4899,
  ); // Swapped to Pink accent for feature highlights
  static const red = Color(0xffEF4444);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xff9CA3AF); // Subtitle grey
  static const textMuted = Color(0xff6B7280); // Tagline/Hint grey

  // Gradients synced perfectly with the brand color scheme (Purple to Pink)
  static const gradient = LinearGradient(
    colors: [
      Color(0xffA855F7), // Purple
      Color(0xffEC4899), // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSoft = LinearGradient(
    colors: [Color(0xff1A142A), Color(0xff0D0A14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class Doctor extends StatefulWidget {
  const Doctor({super.key});

  @override
  State<Doctor> createState() => _DoctorState();
}

class _DoctorState extends State<Doctor> with SingleTickerProviderStateMixin {
  List<bool> favList = [];
  List<Map<String, dynamic>> dermatologistList = [];
  late AnimationController _ctrl;
  late Animation<double> _fade;

  Future<void> fetchdermatologist() async {
    try {
      final response = await supabase.from('tbl_dermatologist').select();
      setState(() {
        dermatologistList = response;
        favList = List.generate(response.length, (_) => false);
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      debugPrint("Error fetching dermatologist: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    fetchdermatologist();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSubHeader(),
            const SizedBox(height: 14),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border(bottom: BorderSide(color: _T.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _T.indigo.withOpacity(0.06),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IndexPage()),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _T.textPrimary,
              size: 16,
            ),
          ),
          const Spacer(),
          Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => _T.gradient.createShader(b),
                child: const Text(
                  'Doctors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'Dermatology Specialists',
                style: TextStyle(
                  color: _T.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          _CircleButton(
            child: ShaderMask(
              shaderCallback: (b) => _T.gradient.createShader(b),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: _T.gradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${dermatologistList.length}',
                      style: const TextStyle(
                        color: _T.indigo,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: ' Specialists',
                      style: TextStyle(
                        color: _T.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.filter_alt_rounded, color: _T.indigo, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: _T.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildGrid() {
    return FadeTransition(
      opacity: _fade,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: dermatologistList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.56,
        ),
        itemBuilder: (context, index) {
          final doctor = dermatologistList[index];
          return _DoctorCard(
            doctor: doctor,
            isFav: favList[index],
            onFavToggle: () => setState(() => favList[index] = !favList[index]),
          );
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final bool isFav;
  final VoidCallback onFavToggle;

  const _DoctorCard({
    required this.doctor,
    required this.isFav,
    required this.onFavToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Docdetail(doc: doctor)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _T.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _T.indigo.withOpacity(0.05),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: _T.gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -18,
                    left: -18,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: 30,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: onFavToggle,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? _T.red : Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _T.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: _T.indigo.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: _T.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: _T.surface,
                    backgroundImage: NetworkImage(
                      doctor['dermatologist_photo'] ?? '',
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -26),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      doctor['dermatologist_name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _T.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _T.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _T.indigo.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        doctor['dermatologist_specilization'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _T.indigo,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.work_history_rounded,
                          color: _T.teal,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          doctor['dermatologist_experience'] ?? '',
                          style: const TextStyle(
                            color: _T.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _T.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _T.indigo.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Docdetail(doc: doctor),
                            ),
                          ),
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _T.cardAlt,
          shape: BoxShape.circle,
          border: Border.all(color: _T.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}
