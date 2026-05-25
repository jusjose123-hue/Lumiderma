
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:userapp/main.dart';

class Stock extends StatefulWidget {
  final String productId;

  const Stock({
    super.key,
    required this.productId,
  });

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  final TextEditingController stockController =
      TextEditingController();

  List<Map<String, dynamic>> stockList = [];

  bool isLoading = true;
  bool isSubmitting = false;
  bool isEdit = false;

  String? editingId;

  /// COLORS

  final Color bgColor = const Color(0xff0B0F1A);
  final Color cardColor = const Color(0xff141B2D);
  final Color primaryColor = const Color(0xff5B8CFF);
  final Color secondaryColor = const Color(0xff7C4DFF);

  @override
  void initState() {
    super.initState();
    fetchStock();
  }

  /// ================= FETCH STOCK =================

  Future<void> fetchStock() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await supabase
          .from('tbl_stock')
          .select()
          .eq('product_id', widget.productId)
          .order('stock_id');

      setState(() {
        stockList =
            List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint(e.toString());

      showSnackBar(
        "Failed to load stock",
        Colors.red,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  

  Future<void> addStock() async {
    if (stockController.text.trim().isEmpty) {
      showSnackBar(
        "Enter stock count",
        Colors.orange,
      );
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      await supabase.from('tbl_stock').insert({
        'stock_count': stockController.text.trim(),
        'product_id': widget.productId,
      });

      stockController.clear();

      showSnackBar(
        "Stock Added",
        Colors.green,
      );

      fetchStock();
    } catch (e) {
      debugPrint(e.toString());

      showSnackBar(
        "Insert Failed",
        Colors.red,
      );
    }

    setState(() {
      isSubmitting = false;
    });
  }

  /// ================= UPDATE STOCK =================

  Future<void> updateStock() async {
    if (stockController.text.trim().isEmpty) {
      showSnackBar(
        "Enter stock count",
        Colors.orange,
      );
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      await supabase
          .from('tbl_stock')
          .update({
            'stock_count':
                stockController.text.trim(),
          })
          .eq('stock_id', editingId!);

      stockController.clear();

      isEdit = false;
      editingId = null;

      showSnackBar(
        "Stock Updated",
        Colors.green,
      );

      fetchStock();
    } catch (e) {
      debugPrint(e.toString());

      showSnackBar(
        "Update Failed",
        Colors.red,
      );
    }

    setState(() {
      isSubmitting = false;
    });
  }

  /// ================= DELETE STOCK =================

  Future<void> deleteStock(
    String stockId,
  ) async {
    try {
      await supabase
          .from('tbl_stock')
          .delete()
          .eq('stock_id', stockId);

      showSnackBar(
        "Stock Deleted",
        Colors.red,
      );

      fetchStock();
    } catch (e) {
      debugPrint(e.toString());

      showSnackBar(
        "Delete Failed",
        Colors.red,
      );
    }
  }

  /// ================= SNACKBAR =================

  void showSnackBar(
    String msg,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            /// ================= LEFT PANEL =================

            Container(
              width: 330,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  right: BorderSide(
                    color:
                        Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// ICON

                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          secondaryColor,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TITLE

                  const Text(
                    "Stock Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Manage product stock count easily using Supabase.",
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(0.6),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// INFO BOX

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        infoTile(
                          "Product ID",
                          widget.productId,
                          Icons.inventory,
                        ),

                        const SizedBox(height: 18),

                        infoTile(
                          "Total Stocks",
                          "${stockList.length}",
                          Icons.stacked_bar_chart,
                        ),

                        const SizedBox(height: 18),

                        infoTile(
                          "Mode",
                          isEdit
                              ? "Editing"
                              : "Adding",
                          Icons.edit,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// STOCK FIELD

                  TextFormField(
                    controller: stockController,
                    keyboardType:
                        TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Stock Count",
                      hintStyle: TextStyle(
                        color:
                            Colors.white.withOpacity(
                          0.4,
                        ),
                      ),
                      filled: true,
                      fillColor: bgColor,
                      prefixIcon: Icon(
                        Icons.production_quantity_limits,
                        color: primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// BUTTON

                  InkWell(
                    onTap: isSubmitting
                        ? null
                        : isEdit
                            ? updateStock
                            : addStock,
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            secondaryColor,
                          ],
                        ),
                      ),
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                isEdit
                                    ? "UPDATE STOCK"
                                    : "ADD STOCK",
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),

                  if (isEdit)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 15,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isEdit = false;
                            editingId = null;
                            stockController.clear();
                          });
                        },
                        borderRadius:
                            BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "CANCEL",
                              style: TextStyle(
                                color: bgColor,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// ================= RIGHT PANEL =================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Product Stock",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Manage and update available product stock",
                      style: TextStyle(
                        color:
                            Colors.white.withOpacity(
                          0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Expanded(
                      child: isLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          : stockList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        Icons
                                            .inventory_2_outlined,
                                        size: 90,
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.2,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 20,
                                      ),

                                      Text(
                                        "No Stock Added",
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                            0.4,
                                          ),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  itemCount:
                                      stockList.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing:
                                        20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio:
                                        1.2,
                                  ),
                                  itemBuilder:
                                      (context, index) {
                                    final stock =
                                        stockList[
                                            index];

                                    return Container(
                                      padding:
                                          const EdgeInsets.all(
                                        20,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            cardColor,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          25,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors
                                                .black
                                                .withOpacity(
                                              0.25,
                                            ),
                                            blurRadius:
                                                12,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16,
                                                  ),
                                                ),
                                                child:
                                                    Icon(
                                                  Icons
                                                      .inventory,
                                                  color:
                                                      primaryColor,
                                                  size:
                                                      28,
                                                ),
                                              ),

                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed:
                                                        () {
                                                      setState(
                                                        () {
                                                          isEdit =
                                                              true;

                                                          editingId =
                                                              stock['stock_id']
                                                                  .toString();

                                                          stockController.text =
                                                              stock['stock_count']
                                                                  .toString();
                                                        },
                                                      );
                                                    },
                                                    icon:
                                                        Icon(
                                                      Icons
                                                          .edit,
                                                      color:
                                                          primaryColor,
                                                    ),
                                                  ),

                                                  IconButton(
                                                    onPressed:
                                                        () {
                                                      deleteStock(
                                                        stock['stock_id']
                                                            .toString(),
                                                      );
                                                    },
                                                    icon:
                                                        const Icon(
                                                      Icons
                                                          .delete,
                                                      color:
                                                          Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const Spacer(),

                                          Text(
                                            "Stock Count",
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 8,
                                          ),

                                          Text(
                                            stock[
                                                    'stock_count']
                                                .toString(),
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .white,
                                              fontSize:
                                                  34,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 10,
                                          ),

                                          Text(
                                            "Stock ID : ${stock['stock_id']}",
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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

  /// ================= INFO TILE =================

  Widget infoTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                primaryColor.withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color:
                      Colors.white.withOpacity(
                    0.5,
                  ),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
