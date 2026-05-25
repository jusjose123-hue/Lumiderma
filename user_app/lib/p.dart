import 'package:admin_app/main.dart';
import 'package:admin_app/prodetail.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  List<Map<String, dynamic>> productList = [];
  bool isLoading = true;

  /// FAVORITE SET
  Set<int> favoriteIndexes = {};

  @override
  void initState() {
    super.initState();
    fetchproduct();
  }

  Future<void> fetchproduct() async {
    try {
      final response = await supabase.from('tbl_product').select(
            '*, tbl_category(category_name), tbl_type(type_name), tbl_heatabsorption(heatabsorption_name),tbl_level(level_name)',
          );

      setState(() {
        productList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D0A14), // Matches registration background
      body: Stack(
        children: [
          // Background Glow Blobs for Visual Consistency
          const Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              size: 320,
              color: Color(0xffA855F7),
              opacity: 0.15,
            ),
          ),
          const Positioned(
            bottom: -80,
            right: -60,
            child: _GlowBlob(
              size: 300,
              color: Color(0xffEC4899),
              opacity: 0.12,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                /// HEADER BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      // Circular back button mirroring registration style
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Products",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                /// BODY GRID
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xffA855F7),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          itemCount: productList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.58, // Adjusted ratio to perfectly fit images, tags, and actions without overflow
                          ),
                          itemBuilder: (context, index) {
                            final product = productList[index];
                            bool isFav = favoriteIndexes.contains(index);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Productdetails(mkdata: product),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xff2D1B4E), // Deep luxury purple base
                                      Color(0xff1C1330),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xffA855F7).withOpacity(0.15),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffA855F7).withOpacity(0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    /// CARD TOP (Category Badge & Fav Icon)
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _badge(
                                            product['tbl_category']?['category_name'] ?? "Category",
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isFav) {
                                                  favoriteIndexes.remove(index);
                                                } else {
                                                  favoriteIndexes.add(index);
                                                }
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isFav
                                                    ? const Color(0xffEC4899).withOpacity(0.15)
                                                    : Colors.white.withOpacity(0.06),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                color: isFav ? const Color(0xffEC4899) : Colors.white54,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// PRODUCT IMAGE (Hero with ambient neon border glow)
                                    Center(
                                      child: Hero(
                                        tag: product['product_name'] ?? "",
                                        child: Container(
                                          height: 94,
                                          width: 94,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xffA855F7).withOpacity(0.4),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xffA855F7).withOpacity(0.2),
                                                blurRadius: 10,
                                              ),
                                            ],
                                            image: DecorationImage(
                                              image: NetworkImage(product['product_photo'] ?? ""),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    /// DETAILS INFO CONTAINER
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            /// NAME
                                            Text(
                                              product['product_name'] ?? "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            /// DYNAMIC WRAPPED TAGS
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                _smallTag(
                                                  product['tbl_type']?['type_name'] ?? "Skin",
                                                  const Color(0xffC084FC), // Subtle lavender
                                                ),
                                                _smallTag(
                                                  product['tbl_heatabsorption']?['heatabsorption_name'] ?? "Heat",
                                                  const Color(0xffEC4899), // Subtle pink
                                                ),
                                              ],
                                            ),

                                            const Spacer(),

                                            /// PRICE
                                            Text(
                                              "₹${product['product_price']}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            /// ACTION CTA BUTTON
                                            Container(
                                              width: double.infinity,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xffA855F7),
                                                    Color(0xffEC4899),
                                                  ],
                                                ),
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => Productdetails(mkdata: product),
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  "Details ✦",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PREMIUM GLASS CHIP CATEGORY BADGE
  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// SYSTEM METRIC SMALL TAGS
  Widget _smallTag(String text, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseColor.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: baseColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// BLUR BLOBS WIDGET FOR VISUAL UNITY
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}