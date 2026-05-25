import 'package:flutter/material.dart';
import 'package:userapp/gallery.dart';
import 'package:userapp/main.dart';
import 'package:userapp/stock.dart';

class Myproducts extends StatefulWidget {
  const Myproducts({super.key});

  @override
  State<Myproducts> createState() => _MyproductsState();
}

class _MyproductsState extends State<Myproducts> {
  List<Map<String, dynamic>> products = [];

  // Theme Constants from place.txt
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color innerBoxColor = Color(0xff111827);
  static const Color accentPurple = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  /// ---------------- FETCH PRODUCTS ----------------
  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('''
        product_id,
        product_name,
        product_price,
        product_photo,
        tbl_category(category_name),
        tbl_type(type_name),
        tbl_heatabsorption(heatabsorption_name),
        tbl_level(level_name),
        tbl_stock(stock_count)
      ''')
          .order('product_id', ascending: false);

      setState(() {
        products = List<Map<String, dynamic>>.from(
          response.map((item) {
            final stockList = item['tbl_stock'] as List? ?? [];

            /// CALCULATE TOTAL STOCK
            int totalStock = stockList.fold(
              0,
              (sum, stock) =>
                  sum + ((stock['stock_count'] ?? 0) as num).toInt(),
            );

            return {...item, 'stock_count': totalStock.toString()};
          }),
        );
      });

      debugPrint("✅ Products fetched: $products");
    } catch (e) {
      debugPrint("❌ Fetch Error: $e");
    }
  }

  Future<void> deleteProduct(int index) async {
    try {
      final id = products[index]['product_id'];

      await supabase.from('tbl_product').delete().eq('product_id', id);
      if (!mounted) return;

      setState(() {
        products.removeAt(index);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product Deleted")));
    } catch (e) {
      debugPrint("❌ Delete Error: $e");
    }
  }

  /// ---------------- DELETE DIALOG ----------------
  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            "Delete Product",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this product?",
            style: TextStyle(color: subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: subTextColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(context);
                deleteProduct(index);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ---------------- CHIP WIDGET ----------------
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "My Products",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                "No Products Found",
                style: TextStyle(fontSize: 16, color: subTextColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardColor,
                    border: Border.all(color: Colors.white.withOpacity(.05)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        /// IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            p['product_photo'] ?? '',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              width: 100,
                              color: innerBoxColor,
                              child: const Icon(
                                Icons.image,
                                size: 40,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['product_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "₹ ${p['product_price'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildChip(
                                    p['tbl_category']?['category_name'] ??
                                        'Category',
                                    const Color(0xff38BDF8), // Light Blue
                                  ),
                                  _buildChip(
                                    p['tbl_type']?['type_name'] ?? 'Type',
                                    accentPurple, // Main Accent Purple
                                  ),
                                  _buildChip(
                                    p['tbl_heatabsorption']?['heatabsorption_name'] ??
                                        'Heat',
                                    Colors.orangeAccent,
                                  ),
                                  _buildChip(
                                    p['tbl_level']?['level_name'] ?? 'Level',
                                    Colors.redAccent,
                                  ),
                                  _buildChip(
                                    "${p['stock_count']} Stock",
                                    const Color(
                                      0xffC4B5FD,
                                    ), // Soft Light Purple text
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        /// ACTIONS
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.store_outlined,
                                color: Color(0xff38BDF8),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Stock(
                                      productId: p['product_id'].toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.collections_outlined,
                                color: Color(0xffC4B5FD),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductGallery(
                                      productId: p['product_id'].toString(),
                                    ),
                                  ),
                                );
                              },
                            ),

                            /// DELETE
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => showDeleteDialog(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
