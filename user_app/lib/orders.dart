import 'dart:async';
import 'package:admin_app/index_page.dart';
import 'package:admin_app/myprofile.dart';
import 'package:admin_app/rating.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:google_fonts/google_fonts.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // Cohesive styling properties tokens
  static const Color bgDark = Color(0xff0D0A14);
  static const Color containerDark = Color(0xff161124);
  static const Color outlineBorder = Color(0xff2A1F3D);
  static const Color dynamicPurple = Color(0xffA855F7);
  static const Color highPink = Color(0xffEC4899);
  static const Color softGrey = Color(0xff9CA3AF);

  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];
  List<Map<String, dynamic>> _returnedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndCategorizeOrders();
  }

  Future<void> _fetchAndCategorizeOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_cart')
          .select('''
            cart_id,
            cart_quantity,
            cart_status,
            booking_id,
            tbl_product (
              product_id,
              product_name,
              product_price,
              product_photo
            ),
            tbl_booking!inner (
              booking_id,
              booking_status,
              booking_amount,
              user_id
            )
          ''')
          .eq('tbl_booking.user_id', user.id);

      final List<Map<String, dynamic>> allRecords =
          List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> active = [];
      final List<Map<String, dynamic>> history = [];
      final List<Map<String, dynamic>> returned = [];

      for (var record in allRecords) {
        final booking = record['tbl_booking'] as Map<String, dynamic>? ?? {};
        final int status =
            int.tryParse(booking['booking_status'].toString()) ?? -1;

        if (status == 2 || status == 4 || status == 5) {
          active.add(record);
        } else if (status == 6) {
          active.add(record);
          history.add(record);
        } else if (status == 8) {
          history.add(record);
          returned.add(record);
        }
      }

      if (mounted) {
        setState(() {
          _activeOrders = active;
          _historyOrders = history;
          _returnedOrders = returned;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("DB FETCH ERROR: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeOrderStatus(
    String bookingId,
    int targetStatus,
    String notificationMsg,
  ) async {
    try {
      await supabase
          .from('tbl_booking')
          .update({'booking_status': targetStatus})
          .eq('booking_id', bookingId);
      if (targetStatus == 7) {
        await supabase
            .from('tbl_cart')
            .update({'cart_status': '7'})
            .eq('booking_id', bookingId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationMsg,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            backgroundColor: dynamicPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchAndCategorizeOrders();
    } catch (e) {
      debugPrint("WORKFLOW ENGINE REJECTION: $e");
    }
  }

  void _openRatingEngine(
    BuildContext context,
    dynamic rawProductId,
    dynamic rawProductName,
  ) {
    final String productId = rawProductId?.toString().trim() ?? '';
    final String productName = rawProductName?.toString().trim() ?? 'Product';

    if (productId.isEmpty || productId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not resolve a valid Product ID.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RatingPage(productId: productId, productName: productName),
      ),
    ).then((_) => _fetchAndCategorizeOrders());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: containerDark,
         leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: outlineBorder,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.35)),
          ),
          child: IconButton(
            onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Myprofile()),
      ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ),
          
          title: Text(
            "My Workspace Panel",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            indicatorColor: highPink,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: highPink,
            unselectedLabelColor: softGrey,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.local_shipping_outlined),
                text: "Order status",
              ),
              Tab(icon: Icon(Icons.history_outlined), text: "History"),
              Tab(icon: Icon(Icons.keyboard_return_outlined), text: "Returned"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: dynamicPurple,
                  strokeWidth: 2,
                ),
              )
            : TabBarView(
                children: [
                  _buildOrderStatusSection(),
                  _buildHistorySection(),
                  _buildReturnedSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    if (_activeOrders.isEmpty)
      return _buildEmptyPlaceholder("No active tracking processes.");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final item = _activeOrders[index];
        final booking = item['tbl_booking'] as Map<String, dynamic>? ?? {};
        final String status = booking['booking_status']?.toString() ?? '2';

        int activeStep = 1;
        String printableStatus = "Paid";
        Color statusColor = Colors.greenAccent;

        if (status == "4") {
          activeStep = 2;
          printableStatus = "Packed";
          statusColor = Colors.blueAccent;
        } else if (status == "5") {
          activeStep = 3;
          printableStatus = "Shipped";
          statusColor = dynamicPurple;
        } else if (status == "6") {
          activeStep = 4;
          printableStatus = "Delivered";
          statusColor = Colors.tealAccent;
        }

        return _buildBaseCardLayout(
          item: item,
          topBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              printableStatus,
              style: GoogleFonts.outfit(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          bottomActions: status == "2"
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _changeOrderStatus(
                    booking['booking_id'].toString(),
                    7,
                    "Order Cancellation processed.",
                  ),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    "Cancel Order",
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          extraContent: Column(
            children: [
              const SizedBox(height: 18),
              Row(
                children: List.generate(4, (i) {
                  bool complete = activeStep > i;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: complete ? statusColor : outlineBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["Paid", "Packed", "Shipped", "Delivered"].map((
                  label,
                ) {
                  return Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: softGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    if (_historyOrders.isEmpty)
      return _buildEmptyPlaceholder("No history operations detected.");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyOrders.length,
      itemBuilder: (context, index) {
        final item = _historyOrders[index];
        final product = item['tbl_product'] as Map<String, dynamic>? ?? {};
        final booking = item['tbl_booking'] as Map<String, dynamic>? ?? {};
        final String status = booking['booking_status']?.toString() ?? '6';

        final bool isReturnedType = status == "8";
        final Color themeColor = isReturnedType ? softGrey : Colors.tealAccent;
        final String badgeTitle = isReturnedType ? "Returned" : "Delivered";

        return _buildBaseCardLayout(
          item: item,
          topBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              badgeTitle,
              style: GoogleFonts.outfit(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          bottomActions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isReturnedType) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff6B7280)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _changeOrderStatus(
                    booking['booking_id'].toString(),
                    8,
                    "Return request logged successfully.",
                  ),
                  icon: const Icon(
                    Icons.assignment_return_outlined,
                    size: 14,
                    color: Color(0xff9CA3AF),
                  ),
                  label: Text(
                    "Return",
                    style: GoogleFonts.outfit(
                      color: const Color(0xffE8EDF4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: highPink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openRatingEngine(
                  context,
                  product['product_id'],
                  product['product_name'],
                ),
                icon: const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  "Rate Product",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReturnedSection() {
    if (_returnedOrders.isEmpty)
      return _buildEmptyPlaceholder("No items inside your return log.");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _returnedOrders.length,
      itemBuilder: (context, index) {
        final item = _returnedOrders[index];
        final product = item['tbl_product'] as Map<String, dynamic>? ?? {};

        return _buildBaseCardLayout(
          item: item,
          topBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: softGrey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: softGrey.withOpacity(0.3), width: 0.8),
            ),
            child: Text(
              "Returned",
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          bottomActions: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: highPink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _openRatingEngine(
              context,
              product['product_id'],
              product['product_name'],
            ),
            icon: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
            label: Text(
              "Rate Product",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBaseCardLayout({
    required Map<String, dynamic> item,
    required Widget topBadge,
    Widget? bottomActions,
    Widget? extraContent,
  }) {
    final product = item['tbl_product'] as Map<String, dynamic>? ?? {};
    final booking = item['tbl_booking'] as Map<String, dynamic>? ?? {};

    final String bId = booking['booking_id']?.toString() ?? 'N/A';
    final String pName = product['product_name'] ?? 'Unknown Item';
    final String pPhoto = product['product_photo'] ?? '';
    final String pPrice = "₹${product['product_price'] ?? 0}";
    final String qty = item['cart_quantity']?.toString() ?? '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ORDER ID: #$bId",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              topBadge,
            ],
          ),
          const Divider(height: 24, color: outlineBorder),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: bgDark,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pPhoto.isNotEmpty
                      ? Image.network(
                          pPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.broken_image_rounded,
                            color: softGrey,
                          ),
                        )
                      : const Icon(Icons.shopping_bag_rounded, color: softGrey),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pPrice,
                      style: GoogleFonts.outfit(
                        color: highPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Qty: $qty",
                      style: GoogleFonts.outfit(color: softGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (extraContent != null) extraContent,
          if (bottomActions != null) ...[
            const Divider(height: 24, color: outlineBorder),
            Align(alignment: Alignment.centerRight, child: bottomActions),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String contextualText) {
    return Center(
      child: Text(
        contextualText,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: softGrey,
        ),
      ),
    );
  }
}
