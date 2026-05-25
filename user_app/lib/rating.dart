import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== COLOR PALETTE ====================
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

  // Derived helpers
  static Color get purpleGlow => accentPurple.withOpacity(0.18);
  static Color get pinkGlow => accentPink.withOpacity(0.15);
  static Color get redGlow => red.withOpacity(0.15);
  static Color get greenGlow => green.withOpacity(0.15);
}

// ==================== RATING MODEL ====================
class RatingModel {
  final int? ratingId;
  final String ratingValue;
  final String ratingContent;
  final String ratingDatetime;
  final String userId;
  final String productId;
  final String userName;
  final String? userAvatarUrl;
  final List<String> attachmentUrls;

  RatingModel({
    this.ratingId,
    required this.ratingValue,
    required this.ratingContent,
    required this.ratingDatetime,
    required this.userId,
    required this.productId,
    this.userName = 'Verified Customer',
    this.userAvatarUrl,
    this.attachmentUrls = const [],
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'rating_value': ratingValue,
      'rating_content': ratingContent,
      'rating_datetime': ratingDatetime,
      'user_id': userId,
      'product_id': int.parse(productId),
    };
    if (ratingId != null) data['rating_id'] = ratingId;
    return data;
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    List<String> urls = [];
    if (map['tbl_gallery'] != null) {
      final List<dynamic> galleryList = map['tbl_gallery'] as List;
      urls = galleryList
          .map((item) => item['gallery_file']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    final userTable = map['tbl_user'] as Map<String, dynamic>?;
    return RatingModel(
      ratingId: int.tryParse(map['rating_id']?.toString() ?? ''),
      ratingValue: map['rating_value']?.toString() ?? '0',
      ratingContent: map['rating_content']?.toString() ?? '',
      ratingDatetime: map['rating_datetime']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '0',
      userName: userTable?['user_name']?.toString() ?? 'Verified Customer',
      userAvatarUrl: userTable?['user_photo']?.toString(),
      attachmentUrls: urls,
    );
  }
}

// ==================== STAR RATING WIDGET ====================
class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Function(int)? onRatingChanged;

  const StarRating({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.size = 30,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final bool filled = index < rating;
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? AppColors.star : AppColors.borderSubtle,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

// ==================== MAIN RATING PAGE ====================
class RatingPage extends StatefulWidget {
  final String productId;
  final String productName;

  const RatingPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> with TickerProviderStateMixin {
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _selectedRating = 0;
  double _averageRating = 0.0;
  List<RatingModel> _ratings = [];
  bool _isLoading = true;
  bool _hasUserRated = false;
  RatingModel? _userRating;
  List<XFile> _selectedImages = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadSupabaseData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _formatDisplayTime(String dbTimeValue) {
    if (dbTimeValue.isEmpty || dbTimeValue == 'null') return 'Today';
    if (dbTimeValue.contains(':')) {
      final elements = dbTimeValue.split(':');
      if (elements.length >= 2) return '${elements[0]}:${elements[1]}';
    }
    return dbTimeValue;
  }

  String _getDatabaseFormattedTime() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)}';
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
    } catch (e) {
      _showSnackBar('Error picking images: $e', AppColors.red);
    }
  }

  void _removeSelectedImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<void> _loadSupabaseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showSnackBar('Session expired. Please log in again.', AppColors.red);
        return;
      }

      final ratingsResponse = await supabase
          .from('tbl_rating')
          .select('''
            *,
            tbl_gallery(gallery_file),
            tbl_user(user_name, user_photo)
          ''')
          .eq('product_id', int.parse(widget.productId));

      final List<RatingModel> loadedRatings = List<Map<String, dynamic>>.from(
        ratingsResponse,
      ).map((m) => RatingModel.fromMap(m)).toList();

      RatingModel? activeUserReview;
      bool userHasRated = false;
      for (var r in loadedRatings) {
        if (r.userId.toLowerCase().trim() == user.id.toLowerCase().trim()) {
          userHasRated = true;
          activeUserReview = r;
          break;
        }
      }

      double calculatedAverage = loadedRatings.isEmpty
          ? 0.0
          : loadedRatings.fold(
                  0.0,
                  (sum, e) => sum + (double.tryParse(e.ratingValue) ?? 0.0),
                ) /
                loadedRatings.length;

      if (mounted) {
        setState(() {
          _ratings = loadedRatings;
          _averageRating = calculatedAverage;
          _hasUserRated = userHasRated;
          _userRating = activeUserReview;
          if (activeUserReview != null) {
            _selectedRating =
                double.tryParse(activeUserReview.ratingValue)?.round() ?? 0;
            _reviewController.text = activeUserReview.ratingContent;
          } else {
            _selectedRating = 0;
            _reviewController.clear();
          }
          _selectedImages.clear();
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('LOAD ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar('Error syncing data: $e', AppColors.red);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      _showSnackBar('Please select a star rating', AppColors.orange);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      _showSnackBar('Please write your review', AppColors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final syncPayload = RatingModel(
        ratingValue: _selectedRating.toString(),
        ratingContent: _reviewController.text.trim(),
        ratingDatetime: _getDatabaseFormattedTime(),
        userId: user.id,
        productId: widget.productId,
      );
      int targetRatingId;

      if (_hasUserRated && _userRating != null) {
        targetRatingId = _userRating!.ratingId!;
        await supabase
            .from('tbl_rating')
            .update(syncPayload.toMap())
            .eq('rating_id', targetRatingId);
        _showSnackBar('Review updated!', AppColors.green);
      } else {
        final insertResponse = await supabase
            .from('tbl_rating')
            .insert(syncPayload.toMap())
            .select('rating_id')
            .single();
        targetRatingId = insertResponse['rating_id'] as int;
        _showSnackBar('Review published!', AppColors.green);
      }

      if (_selectedImages.isNotEmpty) {
        for (var imageFile in _selectedImages) {
          final fileBytes = await imageFile.readAsBytes();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
          final storagePath = 'gallery/${widget.productId}/$fileName';
          await supabase.storage
              .from('Product')
              .uploadBinary(
                storagePath,
                fileBytes,
                fileOptions: const FileOptions(upsert: true),
              );
          final String publicUrl = supabase.storage
              .from('Product')
              .getPublicUrl(storagePath);
          await supabase.from('tbl_gallery').insert({
            'gallery_file': publicUrl,
            'product_id': int.parse(widget.productId),
            'rating_id': targetRatingId,
          });
        }
      }
      await _loadSupabaseData();
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      _showSnackBar('Failed to submit review: $e', AppColors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRating() async {
    if (_userRating == null || _userRating!.ratingId == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.redGlow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.red.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Remove Review?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete your public review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          await supabase
                              .from('tbl_rating')
                              .delete()
                              .eq('rating_id', _userRating!.ratingId!);
                          _showSnackBar('Review deleted.', AppColors.green);
                          await _loadSupabaseData();
                        } catch (e) {
                          _showSnackBar(
                            'Error deleting review: $e',
                            AppColors.red,
                          );
                          setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.red
                  ? Icons.error_outline_rounded
                  : color == AppColors.orange
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.cardColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRODUCT REVIEW',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              widget.productName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accentPurple,
                      ),
                      backgroundColor: AppColors.borderSubtle,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading reviews…',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAverageRatingCard(),
                    const SizedBox(height: 16),
                    _buildSubmitFormCard(),
                    const SizedBox(height: 28),
                    _buildReviewsHeader(),
                    const SizedBox(height: 14),
                    if (_ratings.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ratings.length,
                        itemBuilder: (context, index) =>
                            _buildReviewCard(_ratings[index]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Section: Reviews header ──
  Widget _buildReviewsHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentPink],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Verified Reviews',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.purpleGlow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
          child: Text(
            '${_ratings.length}',
            style: const TextStyle(
              color: AppColors.accentPurple,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Section: Average Rating Card ──
  Widget _buildAverageRatingCard() {
    return _card(
      child: Row(
        children: [
          // Big score with gradient text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.accentPurple, AppColors.accentPink],
                ).createShader(bounds),
                child: Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              StarRating(rating: _averageRating.round(), size: 20),
              const SizedBox(height: 6),
              Text(
                '${_ratings.length} ${_ratings.length == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Bar chart
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final starNum = 5 - i;
                final count = _ratings
                    .where(
                      (r) =>
                          (double.tryParse(r.ratingValue)?.round() ?? 0) ==
                          starNum,
                    )
                    .length;
                final fraction = _ratings.isEmpty
                    ? 0.0
                    : count / _ratings.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                        child: Text(
                          '$starNum',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.star,
                        size: 10,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: AppColors.borderSubtle,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.accentPurple,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Submit Form Card ──
  Widget _buildSubmitFormCard() {
    final labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
    final labelColors = [
      Colors.transparent,
      AppColors.red,
      AppColors.orange,
      AppColors.star,
      AppColors.green,
      AppColors.accentPurple,
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.purpleGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _hasUserRated ? 'Edit Your Review' : 'Write a Review',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Star selector
          Center(
            child: Column(
              children: [
                const Text(
                  'TAP TO RATE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                StarRating(
                  rating: _selectedRating,
                  size: 44,
                  onRatingChanged: (r) => setState(() => _selectedRating = r),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedRating > 0
                      ? Container(
                          key: ValueKey(_selectedRating),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: labelColors[_selectedRating].withOpacity(
                              0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: labelColors[_selectedRating].withOpacity(
                                0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            labels[_selectedRating],
                            style: TextStyle(
                              color: labelColors[_selectedRating],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        )
                      : const SizedBox(height: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Review text field
          _fieldLabel('YOUR THOUGHTS'),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Share your experience with this product…',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.accentPurple,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 22),

          // Photo picker
          _fieldLabel('ATTACH PHOTOS'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purpleGlow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.accentPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to add photos',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, idx) => Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10, top: 8),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImages[idx].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeSelectedImage(idx),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _submitRating,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentPink],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasUserRated
                              ? Icons.edit_rounded
                              : Icons.send_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasUserRated ? 'Update Review' : 'Submit Review',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_hasUserRated) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _deleteRating,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.redGlow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.red.withOpacity(0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Section: Empty State ──
  Widget _buildEmptyState() {
    return _card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.purpleGlow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.reviews_outlined,
                  color: AppColors.accentPurple,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No reviews yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Be the first to share your experience',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section: Single Review Card ──
  Widget _buildReviewCard(RatingModel rating) {
    final int parsedStars = double.tryParse(rating.ratingValue)?.round() ?? 0;
    final bool isCurrentUser =
        rating.userId.toLowerCase().trim() ==
        (supabase.auth.currentUser?.id.toLowerCase().trim() ?? '');

    final sentimentLabel = parsedStars >= 4
        ? '★ Top Rated'
        : parsedStars <= 2
        ? '⚠ Critical'
        : '● Mixed';
    final sentimentColor = parsedStars >= 4
        ? AppColors.green
        : parsedStars <= 2
        ? AppColors.red
        : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.accentPurple.withOpacity(0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPurple.withOpacity(0.3),
                      AppColors.accentPink.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isCurrentUser
                        ? AppColors.accentPurple.withOpacity(0.5)
                        : AppColors.borderSubtle,
                    width: 1.5,
                  ),
                ),
                child:
                    rating.userAvatarUrl != null &&
                        rating.userAvatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          rating.userAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: AppColors.accentPurple,
                            size: 20,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          rating.userName.isNotEmpty
                              ? rating.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.accentPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rating.userName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purpleGlow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accentPurple.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: AppColors.accentPurple,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    StarRating(rating: parsedStars, size: 13),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDisplayTime(rating.ratingDatetime),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sentimentLabel,
                    style: TextStyle(
                      color: sentimentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              rating.ratingContent,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          if (rating.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rating.attachmentUrls.length,
                itemBuilder: (context, imgIdx) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                    image: DecorationImage(
                      image: NetworkImage(rating.attachmentUrls[imgIdx]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared helpers ──
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}
