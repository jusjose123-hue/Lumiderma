import 'dart:async';
import 'package:admin_app/main.dart';
import 'package:admin_app/rating_view.dart';
import 'package:flutter/material.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class AppColors {
  static const Color bgDark = Color(0xff0D0A14);
  static const Color cardColor = Color(0xff161124);
  static const Color borderSubtle = Color(0xff2A1F3D);
  static const Color accentPurple = Color(0xffA855F7);
  static const Color accentPink = Color(0xffEC4899);
  static const Color textPrimary = Color(0xffF9FAFB);
  static const Color textSecondary = Color(0xff9CA3AF);
  static const Color textMuted = Color(0xff6B7280);
  static const Color surfaceColor = Color(0xff1C1530);
  static const Color green = Color(0xff22C55E);
  static const Color orange = Color(0xffF59E0B);
  static const Color red = Color(0xffEF4444);
  static const Color star = Color(0xffFBBF24);
}
// ─────────────────────────────────────────────────────────────────────────────

class Productdetails extends StatefulWidget {
  const Productdetails({super.key, required this.mkdata});
  final Map<String, dynamic> mkdata;

  @override
  State<Productdetails> createState() => _ProductdetailsState();
}

class _ProductdetailsState extends State<Productdetails>
    with SingleTickerProviderStateMixin {
  bool isFav = false;

  Map<String, dynamic>? product;
  bool isLoading = true;
  bool isReviewsLoading = true;

  List<Map<String, dynamic>> galleryImages = [];
  List<Map<String, dynamic>> productReviews = [];
  double averageRating = 0.0;
  int totalReviewCount = 0;

  final ScrollController _mainScrollController = ScrollController();
  final PageController _pageController = PageController();

  int currentImage = 0;
  Timer? _timer;
  int stockCount = 0;

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  Map<int, double> ratingBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
    fetchProduct();
    fetchProductReviews();
  }

  Future<void> fetchProduct() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('''
            *,
            tbl_category(category_name),
            tbl_type(type_name),
            tbl_heatabsorption(heatabsorption_name),
            tbl_level(level_name)
          ''')
          .eq('product_id', widget.mkdata['product_id'])
          .maybeSingle();

      if (response == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      product = response;
      await Future.wait([fetchGallery(), fetchStock()]);

      if (mounted) {
        setState(() => isLoading = false);
        startAutoScroll();
        _fabAnimController.forward();
      }
    } catch (e) {
      debugPrint("Fetch Product Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchProductReviews() async {
    try {
      final response = await supabase
          .from('tbl_rating')
          .select('*, tbl_user(user_name)')
          .eq('product_id', widget.mkdata['product_id']);

      final List<Map<String, dynamic>> loaded = List<Map<String, dynamic>>.from(
        response,
      );

      double sum = 0.0;
      Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var r in loaded) {
        final val =
            double.tryParse(r['rating_value']?.toString() ?? '0') ?? 0.0;
        sum += val;
        final star = val.round().clamp(1, 5);
        counts[star] = (counts[star] ?? 0) + 1;
      }

      Map<int, double> breakdown = {};
      for (int s = 1; s <= 5; s++) {
        breakdown[s] = loaded.isNotEmpty
            ? (counts[s]! / loaded.length) * 100
            : 0;
      }

      if (mounted) {
        setState(() {
          productReviews = loaded;
          totalReviewCount = loaded.length;
          averageRating = loaded.isNotEmpty ? (sum / loaded.length) : 0.0;
          ratingBreakdown = breakdown;
          isReviewsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Reviews Error: $e");
      if (mounted) setState(() => isReviewsLoading = false);
    }
  }

  Future<void> fetchStock() async {
    try {
      if (product == null) return;
      final productId = product!['product_id'];

      final stockResponse = await supabase
          .from('tbl_stock')
          .select('stock_count')
          .eq('product_id', productId);

      int totalStock = 0;
      for (var item in stockResponse) {
        totalStock += int.tryParse(item['stock_count'].toString()) ?? 0;
      }

      final cartResponse = await supabase
          .from('tbl_cart')
          .select('cart_quantity')
          .eq('product_id', productId)
          .eq('cart_status', '2');

      int purchasedQty = 0;
      for (var item in cartResponse) {
        purchasedQty += int.tryParse(item['cart_quantity'].toString()) ?? 0;
      }

      if (!mounted) return;
      setState(() {
        stockCount = (totalStock - purchasedQty).clamp(0, 9999);
      });
    } catch (e) {
      debugPrint("Stock Fetch Error: $e");
    }
  }

  Future<void> fetchGallery() async {
    try {
      if (product == null) return;
      final response = await supabase
          .from('tbl_gallery')
          .select()
          .eq('product_id', product!['product_id']);

      if (mounted) {
        setState(() {
          galleryImages = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
  }

  void startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || product == null) {
        timer.cancel();
        return;
      }
      final allImages = _buildImageList();
      if (allImages.length <= 1) return;
      currentImage = currentImage < allImages.length - 1 ? currentImage + 1 : 0;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          currentImage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<String> _buildImageList() {
    if (product == null) return [];
    return [
      product!['product_photo']?.toString() ?? '',
      ...galleryImages.map((e) => e['gallery_file'].toString()),
    ].where((img) => img.isNotEmpty).toList();
  }

  Future<void> _addToCart(BuildContext context) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _snack(
        context,
        "Please log in to add items to your cart",
        AppColors.orange,
      );
      return;
    }
    if (product == null) {
      _snack(context, "Product details haven't loaded yet.", AppColors.orange);
      return;
    }
    if (stockCount <= 0) {
      _snack(context, "Sorry, this item is Out of Stock!", AppColors.red);
      return;
    }

    try {
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .eq('booking_status', '0')
          .maybeSingle();

      dynamic bookingId;

      if (booking != null) {
        bookingId = booking['booking_id'];
        final existing = await supabase
            .from('tbl_cart')
            .select()
            .eq('booking_id', bookingId)
            .eq('product_id', product!['product_id'])
            .maybeSingle();

        if (existing != null) {
          if (context.mounted) {
            _snack(context, "Already in your cart", AppColors.accentPurple);
          }
          return;
        }
      } else {
        final nb = await supabase
            .from('tbl_booking')
            .insert({
              'user_id': user.id,
              'booking_status': 0,
              'booking_amount': 0,
              'booking_date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        bookingId = nb['booking_id'];
      }

      final insertResult = await supabase.from('tbl_cart').insert({
        'booking_id': bookingId,
        'product_id': product!['product_id'],
        'cart_quantity': 1,
        'cart_status': 0,
      }).select();

      if (insertResult.isEmpty) throw Exception("Empty response from DB.");

      await fetchStock();
      if (context.mounted) {
        _snack(context, "Added to cart ✓", AppColors.green);
      }
    } catch (e) {
      debugPrint("Cart Error: $e");
      if (context.mounted) {
        _snack(context, "Failed to add: ${e.toString()}", AppColors.red);
      }
    }
  }

  void _snack(BuildContext context, String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return "Recent";
    final s = raw.toString();
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length >= 2) return "Today ${parts[0]}:${parts[1]}";
    }
    return s;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _mainScrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accentPurple,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Text(
            "Product could not be loaded.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final data = product!;
    final allImages = _buildImageList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _buildFloatingCartButton(context),
      ),
      body: SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildImageHero(data, allImages),
            if (allImages.length > 1) _buildThumbnails(allImages),
            const SizedBox(height: 16),
            _buildProductHeader(data),
            const SizedBox(height: 12),
            _buildSpecsGrid(data),
            const SizedBox(height: 12),
            _buildDescriptionCard(data),
            const SizedBox(height: 12),
            _buildReviewsCard(),
            // Extra bottom padding so FAB doesn't cover content
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartButton(BuildContext context) {
    final bool outOfStock = stockCount <= 0;
    final bool lowStock = stockCount > 0 && stockCount < 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: outOfStock
            ? null
            : const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentPink],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: outOfStock ? AppColors.surfaceColor : null,
        border: outOfStock ? Border.all(color: AppColors.borderSubtle) : null,
        boxShadow: outOfStock
            ? null
            : [
                BoxShadow(
                  color: AppColors.accentPurple.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _addToCart(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  outOfStock
                      ? Icons.remove_shopping_cart_rounded
                      : Icons.shopping_bag_rounded,
                  color: outOfStock ? AppColors.textMuted : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  outOfStock
                      ? "Out of Stock"
                      : lowStock
                      ? "Add to Cart  ·  Only $stockCount left"
                      : "Add to Cart",
                  style: TextStyle(
                    color: outOfStock ? AppColors.textMuted : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image Hero ────────────────────────────────────────────────────────────
  Widget _buildImageHero(Map<String, dynamic> data, List<String> allImages) {
    return Stack(
      children: [
        SizedBox(
          height: 380,
          width: double.infinity,
          child: allImages.isEmpty
              ? Container(
                  color: AppColors.cardColor,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: allImages.length,
                  onPageChanged: (i) => setState(() => currentImage = i),
                  itemBuilder: (_, i) => Image.network(
                    allImages[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.cardColor,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.bgDark.withOpacity(0.7),
                  AppColors.bgDark,
                ],
                stops: const [0.3, 0.75, 1.0],
              ),
            ),
          ),
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _glassBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _glassBtn(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isFav
                      ? AppColors.accentPink
                      : AppColors.textSecondary,
                  onTap: () => setState(() => isFav = !isFav),
                ),
              ],
            ),
          ),
        ),

        // Nav arrows
        if (allImages.length > 1) ...[
          _navArrow(
            isLeft: true,
            onTap: () {
              if (currentImage > 0) {
                currentImage--;
                _pageController.animateToPage(
                  currentImage,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          _navArrow(
            isLeft: false,
            onTap: () {
              if (currentImage < allImages.length - 1) {
                currentImage++;
                _pageController.animateToPage(
                  currentImage,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ],

        // Dot indicators
        if (allImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allImages.length, (i) {
                final active = currentImage == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accentPurple
                        : AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _glassBtn({
    required IconData icon,
    Color iconColor = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardColor.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _navArrow({required bool isLeft, required VoidCallback onTap}) {
    return Positioned(
      left: isLeft ? 12 : null,
      right: isLeft ? null : 12,
      top: 120,
      bottom: 60,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardColor.withOpacity(0.75),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(
              isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ── Thumbnails ────────────────────────────────────────────────────────────
  Widget _buildThumbnails(List<String> allImages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: SizedBox(
        height: 68,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allImages.length,
          itemBuilder: (_, i) {
            final selected = currentImage == i;
            return GestureDetector(
              onTap: () {
                setState(() => currentImage = i);
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.accentPurple
                        : AppColors.borderSubtle,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    allImages[i],
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 58,
                      height: 58,
                      color: AppColors.surfaceColor,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Product Header (name, price, rating, stock) ───────────────────────────
  Widget _buildProductHeader(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data['product_name'] ?? "No Name",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _stockBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Price pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentPink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "₹ ${data['product_price'] ?? '0'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductReviewsPage(
                      productId: data['product_id']?.toString() ?? '',
                      productName:
                          data['product_name']?.toString() ?? 'Reviews',
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.star,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      averageRating > 0
                          ? averageRating.toStringAsFixed(1)
                          : "—",
                      style: const TextStyle(
                        color: AppColors.star,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "($totalReviewCount reviews)",
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textMuted,
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

  Widget _stockBadge() {
    final Color color = stockCount <= 0
        ? AppColors.red
        : stockCount < 10
        ? AppColors.orange
        : AppColors.green;
    final String label = stockCount <= 0
        ? "Out of Stock"
        : stockCount < 10
        ? "$stockCount left"
        : "In Stock";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Specs Grid ────────────────────────────────────────────────────────────
  Widget _buildSpecsGrid(Map<String, dynamic> data) {
    final specs = [
      _SpecItem(
        Icons.category_rounded,
        "Category",
        data['tbl_category']?['category_name'] ?? "N/A",
        AppColors.accentPurple,
      ),
      _SpecItem(
        Icons.spa_rounded,
        "Skin Type",
        data['tbl_type']?['type_name'] ?? "N/A",
        AppColors.green,
      ),
      _SpecItem(
        Icons.local_fire_department_rounded,
        "Heat Absorption",
        data['tbl_heatabsorption']?['heatabsorption_name'] ?? "N/A",
        AppColors.orange,
      ),
      _SpecItem(
        Icons.bar_chart_rounded,
        "Level",
        data['tbl_level']?['level_name'] ?? "N/A",
        AppColors.accentPink,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: specs.map((s) => _specTile(s)).toList(),
      ),
    );
  }

  Widget _specTile(_SpecItem s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(s.icon, color: s.color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  s.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Description Card ──────────────────────────────────────────────────────
  Widget _buildDescriptionCard(Map<String, dynamic> data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("About this product"),
          const SizedBox(height: 10),
          Text(
            data['product_description'] ?? "No description available.",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 8),
          // Share row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        color: AppColors.accentPurple,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Share",
                        style: TextStyle(
                          color: AppColors.accentPurple,
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
        ],
      ),
    );
  }

  // ── Reviews Card ──────────────────────────────────────────────────────────
  Widget _buildReviewsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle("Reviews"),
              GestureDetector(
                onTap: () {
                  if (product == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductReviewsPage(
                        productId: product!['product_id']?.toString() ?? '',
                        productName:
                            product!['product_name']?.toString() ?? 'Reviews',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentPurple.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    "View all",
                    style: TextStyle(
                      color: AppColors.accentPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average + bar breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentPink],
                    ).createShader(bounds),
                    child: Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _starRow(averageRating),
                  const SizedBox(height: 4),
                  Text(
                    "$totalReviewCount ratings",
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((s) {
                    final pct = ratingBreakdown[s] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            "$s",
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 5,
                                backgroundColor: AppColors.borderSubtle,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  s <= 2 && pct > 0
                                      ? AppColors.red
                                      : AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "${pct.round()}%",
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          _divider(),

          if (isReviewsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: AppColors.accentPurple,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (productReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.textMuted.withOpacity(0.5),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "No reviews yet.",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...productReviews.take(3).map((r) => _reviewTile(r)),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final double val =
        double.tryParse(r['rating_value']?.toString() ?? '0') ?? 0;
    final String name = r['tbl_user']?['user_name']?.toString() ?? "User";
    final String initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : "U";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _starRow(val, size: 12),
                  ],
                ),
              ),
              Text(
                _formatTime(r['rating_time']),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if ((r['rating_content'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r['rating_content'].toString(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _starRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_border_rounded,
          color: AppColors.star,
          size: size,
        );
      }),
    );
  }

  // ── Shared ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _divider() => Container(
    height: 0.5,
    color: AppColors.borderSubtle,
    margin: const EdgeInsets.symmetric(vertical: 16),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );
}

// Helper class for spec tiles
class _SpecItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SpecItem(this.icon, this.label, this.value, this.color);
}
