import 'dart:convert';
import 'package:admin_app/gemini_service.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/p.dart';
import 'package:admin_app/prodetail.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Added Lottie package dependency

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF141420);
  static const Color gold = Color(0xffA855F7);
  static const Color copper = Color.fromARGB(255, 96, 29, 62);
  static const Color glass = Color(0xFF1E1E2E);
  static const Color accent = Color(0xFF6C63FF);

  double uvIndex = 0.0;
  String temperature = "--";
  String locationName = "Detecting location...";
  bool isLoading = true;
  List<dynamic> recommendedProducts = [];

  String? userSkinType;
  String? userSkinTypeName;
  String? aiLog;
  String? userName;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _initLocationAndWeather();
    _loadUserName();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tbl_user')
            .select('user_name')
            .eq('user_id', user.id)
            .single();
        if (mounted) setState(() => userName = data['user_name']);
      }
    } catch (_) {}
  }

  Future<void> _initLocationAndWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          locationName = "Kerala";
          isLoading = false;
        });
        _fetchWeather(20.5937, 78.9629);
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _fetchWeather(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        locationName = "Kerala";
      });
      _fetchWeather(20.5937, 78.9629);
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      // FIX: Added a custom User-Agent header 'curl' and reformatted the URL coordinates.
      // This forces wttr.in to process coordinates correctly instead of defaulting to country nodes.
      final res = await http
          .get(
            Uri.parse('https://wttr.in/$lat,$lon?format=j1'),
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'curl/7.81.0', // Critical: tells wttr.in to handle coordinates properly
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        if (!res.body.trimLeft().startsWith('{')) {
          throw Exception("wttr.in returned non-JSON response");
        }

        final data = json.decode(res.body);
        final current = data['current_condition'][0];
        final area = data['nearest_area'][0];

        setState(() {
          // FIX: wttr.in stores uvIndex under weather -> hourly -> uvIndex for precise daily matches,
          // but if using current_condition, ensure it maps explicitly with default checks.
          uvIndex =
              double.tryParse(current['uvIndex']?.toString() ?? "0") ?? 0.0;
          temperature = current['temp_C'] ?? "--";
          locationName =
              "${area['areaName'][0]['value']}, ${area['region'][0]['value']}";
        });

        // These are now guaranteed correct inputs to fetch matching products
        await _fetchRecommendedProducts();
        await _fetchAiLog();
      } else {
        throw Exception("HTTP ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Weather fetch error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          locationName = "Location unavailable";
        });
      }
    }
  }

  Future<void> _fetchAiLog() async {
    try {
      final advice = await GeminiService.getSkinCareAdvice(
        uvIndex,
        userSkinTypeName ?? userSkinType,
      );
      if (mounted) {
        setState(() {
          aiLog = advice;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AI log error: $e");
      if (mounted) {
        setState(() {
          aiLog = "Could not load skin advice. Please refresh.";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendedProducts() async {
    try {
      final user = supabase.auth.currentUser;
      int? parsedSkinType;

      if (user != null) {
        final d = await supabase
            .from('tbl_user')
            .select('type_id')
            .eq('user_id', user.id)
            .single();

        parsedSkinType = _parseInt(d['type_id']);
        userSkinType = parsedSkinType?.toString();

        if (parsedSkinType != null) {
          final typeRes = await supabase
              .from('tbl_type')
              .select('type_name')
              .eq('type_id', parsedSkinType)
              .maybeSingle();

          userSkinTypeName = typeRes?['type_name']?.toString();
        }
      }

      final response = await supabase
          .from('tbl_product')
          .select('*, tbl_type(type_name), tbl_level(level_name)');

      final targetLevel = _getUvLevel(uvIndex).toLowerCase();
      final targetTypeName = userSkinTypeName?.trim().toLowerCase() ?? '';
      final allProducts = List<Map<String, dynamic>>.from(response);

      List<Map<String, dynamic>> filteredProducts = allProducts.where((product) {
        final levelName =
            (product['tbl_level']?['level_name'] ?? '').toString().toLowerCase();
        final typeName =
            (product['tbl_type']?['type_name'] ?? '').toString().toLowerCase();
        final productTypeId = _parseInt(product['type_id']);

        final matchesLevel =
            levelName.isEmpty || levelName.contains(targetLevel);
        final matchesType = targetTypeName.isEmpty
            ? productTypeId == parsedSkinType || parsedSkinType == null
            : typeName == targetTypeName || productTypeId == parsedSkinType;

        return matchesLevel && matchesType;
      }).toList();

      if (filteredProducts.isEmpty && targetTypeName.isNotEmpty) {
        filteredProducts = allProducts.where((product) {
          final typeName =
              (product['tbl_type']?['type_name'] ?? '').toString().toLowerCase();
          final productTypeId = _parseInt(product['type_id']);
          return typeName == targetTypeName || productTypeId == parsedSkinType;
        }).toList();
      }

      if (filteredProducts.isEmpty) {
        filteredProducts = allProducts.where((product) {
          final levelName =
              (product['tbl_level']?['level_name'] ?? '').toString().toLowerCase();
          return levelName.isEmpty || levelName.contains(targetLevel);
        }).toList();
      }

      if (filteredProducts.isEmpty) {
        filteredProducts = allProducts;
      }

      final recommendations = filteredProducts.take(8).toList();

      if (mounted) {
        setState(() => recommendedProducts = recommendations);
      }
    } catch (e) {
      debugPrint("Product Error: $e");
      if (mounted) {
        setState(() => recommendedProducts = []);
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _getUvLevel(double uv) {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }

  String _getDailyProtectionTitle() {
    final skinType = userSkinTypeName ?? 'Your skin';
    // final uvLevel = _getUvLevel(uvIndex);
    return 'Daily Protection • $skinType ';
  }

  Color _getUvColor(double uv) {
    if (uv <= 2) return const Color(0xFF4CAF50);
    if (uv <= 5) return const Color(0xFFFFEB3B);
    if (uv <= 7) return const Color(0xFFFF9800);
    if (uv <= 10) return const Color(0xFFF44336);
    return const Color(0xFF9C27B0);
  }

  String _getUvLottieAsset(double uv) {
    if (uv <= 2) return "assets/smi.json";
    if (uv <= 5) return "assets/clo.json";
    if (uv <= 7) return "assets/sun.json";
    if (uv <= 10) return "assets/fire.json";
    return "assets/war.json";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: bgBlack,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            color: gold,
            backgroundColor: darkCard,
            onRefresh: _initLocationAndWeather,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                /// ── TOP HEADER ──
                SliverToBoxAdapter(child: _buildHeader()),

                /// ── UV HERO CARD ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildUVHeroCard(),
                  ),
                ),

                /// ── UV GAUGE BAR ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _buildUVGaugeBar(),
                  ),
                ),

                /// ── AI SKIN LOG ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _buildSection(
                      title: "AI Skin Care Log",
                      icon: Icons.auto_awesome_rounded,
                      child: _buildAiLog(),
                    ),
                  ),
                ),

                /// ── RECOMMENDED PRODUCTS ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          _getDailyProtectionTitle(),
                          Icons.spa_rounded,
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Products()),
                          ),
                          child: Text(
                            "See All",
                            style: GoogleFonts.outfit(
                              color: gold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: gold,
                              strokeWidth: 2,
                            ),
                          )
                        : recommendedProducts.isEmpty
                        ? Center(
                            child: Text(
                              "Finding ${userSkinTypeName ?? 'your'} ${_getUvLevel(uvIndex).toLowerCase()} protection matches...",
                              style: GoogleFonts.outfit(color: Colors.white24),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: recommendedProducts.length,
                            itemBuilder: (ctx, i) =>
                                _buildProductChip(recommendedProducts[i]),
                          ),
                  ),
                ),

                /// ── BOOK A DERM ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: _buildDoctorBanner(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 55, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [copper.withOpacity(.3), bgBlack],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName != null
                    ? "Hello, ${userName!.split(' ')[0]} 👋"
                    : "Hello 👋",
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 2),
              Text(
                "UV Sense",
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: glass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withOpacity(.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: gold, size: 14),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        locationName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUVHeroCard() {
    final uvColor = _getUvColor(uvIndex);
    final uvLevel = _getUvLevel(uvIndex);
    final lottieAsset = _getUvLottieAsset(
      uvIndex,
    ); // Changed from static emoji calculation

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [uvColor.withOpacity(.25), darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: uvColor.withOpacity(.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: uvColor.withOpacity(.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: isLoading
          ? const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: gold, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$temperature°C",
                          style: GoogleFonts.outfit(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: uvColor.withOpacity(.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: uvColor.withOpacity(.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny_rounded,
                                color: uvColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "UV $uvLevel · Index ${uvIndex.toStringAsFixed(1)}",
                                style: GoogleFonts.outfit(
                                  color: uvColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: uvColor.withOpacity(.1),
                        border: Border.all(
                          color: uvColor.withOpacity(.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          lottieAsset,
                          width: 55,
                          height: 55,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildUVGaugeBar() {
    final uvColor = _getUvColor(uvIndex);
    final pct = (uvIndex / 11).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "UV Exposure Risk",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              ),
              Text(
                _getUvLevel(uvIndex),
                style: GoogleFonts.outfit(
                  color: uvColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation<Color>(uvColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Low", "Moderate", "High", "Very High", "Extreme"]
                .map(
                  (l) => Text(
                    l,
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiLog() {
    if (aiLog == null) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: gold, strokeWidth: 2),
          ),
          const SizedBox(width: 15),
          Text(
            "Analyzing skin data...",
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
          ),
        ],
      );
    }

    List<String> lines = aiLog!.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty) return const SizedBox(height: 8);

        if (trimmedLine.startsWith('**') && trimmedLine.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lines.indexOf(line) != 0)
                  Divider(
                    color: gold.withOpacity(0.1),
                    thickness: 1,
                    height: 24,
                  ),
                Text(
                  trimmedLine.replaceAll('**', '').toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }

        if (trimmedLine.contains('Elite Tip') || trimmedLine.startsWith('*')) {
          return _buildAdviceTile(trimmedLine);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            trimmedLine.replaceAll('**', ''),
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdviceTile(String text) {
    String cleanText = text.replaceAll('*', '').replaceAll('**', '').trim();
    bool isTip = cleanText.contains('Elite Tip');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isTip
                ? Icons.lightbulb_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isTip ? gold : const Color(0xFF81C784),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gold.withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: gold, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildProductChip(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Productdetails(mkdata: item)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withOpacity(.12)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child:
                  item['product_photo'] != null &&
                      item['product_photo'].toString().isNotEmpty
                  ? Image.network(
                      item['product_photo'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: darkCard,
                        child: const Icon(
                          Icons.spa_outlined,
                          color: gold,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: darkCard,
                      child: const Icon(
                        Icons.spa_outlined,
                        color: gold,
                        size: 40,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${item['product_price'] ?? '0'}",
                    style: GoogleFonts.outfit(
                      color: gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xffA855F7), Color.fromARGB(255, 91, 3, 47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Specialist Care",
                    style: GoogleFonts.outfit(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Book a Dermatologist",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Expert guidance for your skin type",
                  style: GoogleFonts.outfit(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tap the Doctor tab below to book"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: gold,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Book Now →",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.medical_services_outlined,
            size: 70,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }
}
