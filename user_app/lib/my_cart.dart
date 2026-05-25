import 'package:admin_app/main.dart';
import 'package:admin_app/payment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyCart extends StatefulWidget {
  const MyCart({super.key});

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  // Synchronized color palette with Welcome, Doctor, and Reviews screens
  static const Color bgBlack = Color(0xff0D0A14);
  static const Color gold = Color(
    0xffEC4899,
  ); // Brand Pink for accents and prices
  static const Color glass = Color(0xff161124); // Card depth shade
  static const Color primaryPurple = Color(
    0xffA855F7,
  ); // Brand Purple for buttons

  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  double grandTotal = 0;
  int? currentBookingId;

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  /// Helper method to safely extract a Map out of the 'tbl_product' data response
  Map<String, dynamic> _extractProductMap(dynamic productData) {
    if (productData is List && productData.isNotEmpty) {
      return Map<String, dynamic>.from(productData[0]);
    } else if (productData is Map) {
      return Map<String, dynamic>.from(productData);
    }
    return {};
  }

  /// ================= FETCH CART DATA =================
  Future<void> fetchCartData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final bookingResponse = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .eq('booking_status', 0)
          .maybeSingle();
      print(bookingResponse);
      if (bookingResponse == null) {
        if (mounted) {
          setState(() {
            cartItems = [];
            currentBookingId = null;
            isLoading = false;
          });
        }
        return;
      }

      currentBookingId = bookingResponse['booking_id'];

      final response = await supabase
          .from('tbl_cart')
          .select(
            'cart_id, booking_id, product_id, cart_quantity, cart_status, tbl_product(*),tbl_booking(*)',
          )
          .eq('booking_id', currentBookingId!);

      if (mounted) {
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(response);
          _calcTotal();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ================= CALCULATE TOTAL =================
  void _calcTotal() {
    grandTotal = cartItems.fold(0.0, (sum, item) {
      final product = _extractProductMap(item['tbl_product']);
      final price = (product['product_price'] as num?)?.toDouble() ?? 0;
      final qty = (item['cart_quantity'] as num?)?.toDouble() ?? 0;
      return sum + (price * qty);
    });
  }

  /// ================= UPDATE QUANTITY WITH STOCK CHECK =================
  Future<void> updateQty(int index, int delta) async {
    try {
      final item = cartItems[index];
      final cartId = item['cart_id'];
      final productId = item['product_id'];
      final int currentQty = (item['cart_quantity'] as num?)?.toInt() ?? 0;
      final int newQty = currentQty + delta;

      /// 1. REMOVE ITEM IF LESS THAN 1
      if (newQty < 1) {
        await deleteItem(cartId, index);
        return;
      }

      /// 2. STOCK VALIDATION (Only check if incrementing)
      if (delta > 0) {
        final stockResponse = await supabase
            .from('tbl_stock')
            .select('stock_count')
            .eq('product_id', productId);

        final int totalStock =
            (stockResponse as List<dynamic>?)?.fold<int>(
              0,
              (sum, element) =>
                  sum + ((element['stock_count'] ?? 0) as num).toInt(),
            ) ??
            0;

        final int globalOrderedQty =
            (await supabase
                        .from('tbl_cart')
                        .select('cart_quantity')
                        .eq('product_id', productId)
                        .eq('cart_status', 2)
                    as List<dynamic>?)
                ?.fold<int>(
                  0,
                  (sum, element) =>
                      sum + ((element['cart_quantity'] ?? 0) as num).toInt(),
                ) ??
            0;

        final int availableStock = totalStock - globalOrderedQty;

        if (newQty > availableStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  availableStock <= 0
                      ? "Product is Out of Stock!"
                      : "Cannot add more. Only $availableStock items left in stock!",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
          return;
        }
      }

      /// 3. UPDATE DATABASE
      await supabase
          .from('tbl_cart')
          .update({'cart_quantity': newQty})
          .eq('cart_id', cartId);

      /// 4. OPTIMIZED LOCAL STATE UPDATE
      if (mounted) {
        setState(() {
          cartItems[index]['cart_quantity'] = newQty;
          _calcTotal();
        });
      }
    } catch (e) {
      debugPrint("❌ Error updating quantity: $e");
    }
  }

  /// ================= DELETE ITEM =================
  Future<void> deleteItem(int cartId, int index) async {
    try {
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);
      if (mounted) {
        setState(() {
          cartItems.removeAt(index);
          _calcTotal();
        });
      }
    } catch (e) {
      debugPrint("Error deleting item: $e");
    }
  }

  /// ================= CLEAR ALL =================
  Future<void> clearAllCart() async {
    if (currentBookingId == null) return;
    try {
      setState(() => isLoading = true);

      await supabase
          .from('tbl_cart')
          .delete()
          .eq('booking_id', currentBookingId!);

      if (mounted) {
        setState(() {
          cartItems.clear();
          grandTotal = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error clearing cart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryPurple),
        title: Text(
          "My Cart",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: clearAllCart,
              child: Text(
                "Clear All",
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
                strokeWidth: 2,
              ),
            )
          : cartItems.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, i) => _buildItem(cartItems[i], i),
                  ),
                ),
                _buildCheckout(),
              ],
            ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, int index) {
    final product = _extractProductMap(item['tbl_product']);
    final double price = (product['product_price'] as num?)?.toDouble() ?? 0;
    final int qty = (item['cart_quantity'] as num?)?.toInt() ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff2A1F3D), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product['product_photo'] != null
                ? Image.network(
                    product['product_photo'],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xff120E1C),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: Color(0xff9CA3AF),
                      size: 30,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${(price * qty).toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _qtyBtn(Icons.remove_rounded, () => updateQty(index, -1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "$qty",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _qtyBtn(Icons.add_rounded, () => updateQty(index, 1)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => deleteItem(item['cart_id'], index),
                child: Text(
                  "Remove",
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(.12),
          shape: BoxShape.circle,
          border: Border.all(color: primaryPurple.withOpacity(.35)),
        ),
        child:  Icon(icon, size: 16, color: primaryPurple),
      ),
    );
  }

  Widget _buildCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(color: const Color(0xff2A1F3D), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${cartItems.length} item${cartItems.length > 1 ? 's' : ''}",
                style: GoogleFonts.outfit(
                  color: const Color(0xff9CA3AF),
                  fontSize: 14,
                ),
              ),
              Text(
                "₹${grandTotal.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                  color: gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [primaryPurple, gold],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (cartItems.isEmpty || currentBookingId == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentGatewayScreen(
                        id: currentBookingId!,
                        amt: grandTotal.toInt(),
                        purchasedItems: cartItems,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  "PAY  ₹${grandTotal.toStringAsFixed(0)}  →",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xff1A142A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xff2A1F3D)),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: primaryPurple.withOpacity(.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: GoogleFonts.outfit(
              color: const Color(0xff9CA3AF),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some products to get started",
            style: GoogleFonts.outfit(
              color: const Color(0xff6B7280),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
