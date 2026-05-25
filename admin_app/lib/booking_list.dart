import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ensure your supabase instance is accessible here.
import 'package:userapp/main.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color accentColor = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  // Grouped by Booking ID: { "17": [list of cart items with product info] }
  Map<String, List<Map<String, dynamic>>> _groupedPaid = {};
  Map<String, List<Map<String, dynamic>>> _groupedPacked = {};
  Map<String, List<Map<String, dynamic>>> _groupedShipped = {};
  Map<String, List<Map<String, dynamic>>> _groupedDelivered = {};
  Map<String, List<Map<String, dynamic>>> _groupedCancelled = {};
  Map<String, List<Map<String, dynamic>>> _groupedReturned =
      {}; // Added for returns
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Parallel processing for all status groups to maximize fetch speeds
      final results = await Future.wait([
        _fetchAndGroup(2), // Paid
        _fetchAndGroup(4), // Packed
        _fetchAndGroup(5), // Shipped
        _fetchAndGroup(6), // Delivered
        _fetchAndGroup(0), // Cancelled
        _fetchAndGroup(8), // Returned (Added status)
      ]);

      if (!mounted) return;

      setState(() {
        _groupedPaid = results[0];
        _groupedPacked = results[1];
        _groupedShipped = results[2];
        _groupedDelivered = results[3];
        _groupedCancelled = results[4];
        _groupedReturned = results[5]; // Added assignment
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchAndGroup(
    int statusId,
  ) async {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    try {
      final response = await supabase
          .from('tbl_booking')
          .select('''
            booking_id,
            booking_date,
            booking_amount,
            tbl_cart (
              cart_quantity,
              tbl_product (
                product_name,
                product_photo,
                product_price
              )
            )
          ''')
          .eq('booking_status', statusId);

      final List<dynamic> data = response as List<dynamic>;

      for (var booking in data) {
        final String bId = booking['booking_id'].toString();

        if (booking['tbl_cart'] != null) {
          final List<Map<String, dynamic>> cartList = List<dynamic>.from(
            booking['tbl_cart'],
          ).map((e) => Map<String, dynamic>.from(e as Map)).toList();

          grouped[bId] = cartList;

          if (grouped[bId]!.isNotEmpty) {
            grouped[bId]![0]['booking_date'] = booking['booking_date'];
            grouped[bId]![0]['total_amount'] = booking['booking_amount'];
          }
        }
      }
    } catch (e) {
      debugPrint("Database Fetch Error for status $statusId: $e");
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6, // Increased to 6 tabs
      child: Scaffold(
        backgroundColor: const Color(0xff0F172A),
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              const TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: accentColor,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                tabs: [
                  Tab(text: "Paid"),
                  Tab(text: "Packed"),
                  Tab(text: "Shipped"),
                  Tab(text: "Delivered"),
                  Tab(text: "Cancelled"),
                  Tab(text: "Returned"), // Added Tab Label
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: accentColor),
                      )
                    : TabBarView(
                        children: [
                          _buildBookingList(_groupedPaid, "Paid"),
                          _buildBookingList(_groupedPacked, "Packed"),
                          _buildBookingList(_groupedShipped, "Shipped"),
                          _buildBookingList(_groupedDelivered, "Delivered"),
                          _buildBookingList(_groupedCancelled, "Cancelled"),
                          _buildBookingList(
                            _groupedReturned,
                            "Returned",
                          ), // Added Tab View
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text(
          "Order Management",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(
    Map<String, List<Map<String, dynamic>>> groupedData,
    String status,
  ) {
    if (groupedData.isEmpty) {
      return Center(
        child: Text(
          "No $status orders found",
          style: const TextStyle(color: Colors.white24),
        ),
      );
    }

    return ListView(
      children: groupedData.entries.map((entry) {
        return _buildBookingCard(entry.key, entry.value, status);
      }).toList(),
    );
  }

  Widget _buildBookingCard(
    String bookingId,
    List<Map<String, dynamic>> cartItems,
    String status,
  ) {
    if (cartItems.isEmpty) return const SizedBox.shrink();
    final meta = cartItems.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 25, 55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ORDER #$bookingId",
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              _buildActionButtons(bookingId, status),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),
          ...cartItems.map((item) {
            final product = item['tbl_product'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product?['product_photo'] != null
                          ? Image.network(
                              product!['product_photo'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white12,
                                  ),
                            )
                          : const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white12,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?['product_name']?.toString() ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Qty: ${item['cart_quantity'] ?? 0}",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${product?['product_price'] ?? '0'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Date: ${meta['booking_date'] != null ? meta['booking_date'].toString().split('T')[0] : 'N/A'}",
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
              Text(
                "Total Amount: ₹${meta['total_amount'] ?? 0}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String status) {
    if (status == "Paid") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.blueAccent,
            ),
            tooltip: 'Mark as Packed',
            onPressed: () => _updateBookingStatus(id, 4), // Set to Packed (4)
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            tooltip: 'Cancel Order',
            onPressed: () =>
                _updateBookingStatus(id, 0), // Set to Cancelled (0)
          ),
        ],
      );
    } else if (status == "Packed") {
      return IconButton(
        icon: const Icon(
          Icons.local_shipping_outlined,
          color: Colors.deepPurpleAccent,
        ),
        tooltip: 'Mark as Shipped',
        onPressed: () => _updateBookingStatus(id, 5), // Set to Shipped (5)
      );
    } else if (status == "Shipped") {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
        tooltip: 'Mark as Delivered',
        onPressed: () => _updateBookingStatus(id, 6), // Set to Delivered (6)
      );
    } else if (status == "Delivered") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.teal),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.assignment_return_outlined,
              color: Colors.blueGrey,
            ),
            tooltip: 'Process Return',
            onPressed: () =>
                _updateBookingStatus(id, 8), // Explicitly Accept Return (8)
          ),
        ],
      );
    } else if (status == "Returned") {
      // Displays a distinct icon indicating the product has returned to warehouse inventory
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard_return, color: Colors.blueGrey),
          SizedBox(width: 4),
          Text(
            "Returned",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.restore, color: Colors.white38),
        tooltip: 'Restore Order',
        onPressed: () => _updateBookingStatus(id, 2), // Restore to Paid (2)
      );
    }
  }

  Future<void> _updateBookingStatus(String id, int newStatus) async {
    try {
      await supabase
          .from('tbl_booking')
          .update({'booking_status': newStatus})
          .eq('booking_id', id);
      _refreshData();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }
}
