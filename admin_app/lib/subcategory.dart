import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class Subcategory extends StatefulWidget {
  const Subcategory({super.key});

  @override
  State<Subcategory> createState() => _SubcategoryState();
}

class _SubcategoryState extends State<Subcategory> {
  final TextEditingController subcategoryController = TextEditingController();

  List<Map<String, dynamic>> _category = [];
  String? _selectedvalue;

  List<Map<String, dynamic>> subcategoryList = [];

  int eid = 0;
  bool isLoading = false;

  final Color primary = const Color(0xff7F5AF0);

  @override
  void initState() {
    super.initState();
    fetchCategory();
    fetchsubcategory();
  }

  /// ================= FETCH CATEGORY =================
  Future<void> fetchCategory() async {
    try {
      final response = await supabase.from('tbl_category').select();

      setState(() {
        _category = List<Map<String, dynamic>>.from(response);

        _selectedvalue = _category.isNotEmpty
            ? _category.first['category_id'].toString()
            : null;
      });
    } catch (e) {
      debugPrint("Category Fetch Error: $e");
    }
  }

  /// ================= FETCH SUBCATEGORY =================
  Future<void> fetchsubcategory() async {
    try {
      final response = await supabase
          .from('tbl_subcategory')
          .select('*, tbl_category(category_name)')
          .order('subcategory_id');

      setState(() {
        subcategoryList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Subcategory Fetch Error: $e");
    }
  }

  /// ================= INSERT / UPDATE =================
  Future<void> handleSubmit() async {
    if (subcategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter subcategory name")),
      );

      return;
    }

    try {
      setState(() => isLoading = true);

      if (eid == 0) {
        await supabase.from('tbl_subcategory').insert({
          'subcategory_name': subcategoryController.text.trim(),
          'category_id': _selectedvalue,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Subcategory Added"),
          ),
        );
      } else {
        await supabase
            .from('tbl_subcategory')
            .update({
              'subcategory_name': subcategoryController.text.trim(),
              'category_id': _selectedvalue,
            })
            .eq('subcategory_id', eid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Subcategory Updated"),
          ),
        );
      }

      subcategoryController.clear();

      setState(() {
        eid = 0;
      });

      fetchsubcategory();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= DELETE =================
  Future<void> deleteSubcategory(int id) async {
    try {
      await supabase.from('tbl_subcategory').delete().eq('subcategory_id', id);

      fetchsubcategory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Deleted Successfully"),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    subcategoryController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              _buildFormCard(),

              const SizedBox(height: 24),

              _buildTableCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= FORM CARD =================
  Widget _buildFormCard() {
    return Card(
      elevation: 20,
      color: const Color(0xff111827),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Subcategory Management",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Create and manage product subcategories",
              style: TextStyle(color: Color(0xff9CA3AF), fontSize: 13),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                /// CATEGORY DROPDOWN
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedvalue,

                    dropdownColor: const Color(0xff1E293B),

                    style: const TextStyle(color: Colors.white),

                    decoration: _inputDecoration(
                      "Select Category",
                      Icons.category_outlined,
                    ),

                    items: _category.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['category_id'].toString(),

                        child: Text(item['category_name'].toString()),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        _selectedvalue = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                /// TEXTFIELD
                Expanded(
                  flex: 2,

                  child: TextFormField(
                    controller: subcategoryController,

                    style: const TextStyle(color: Colors.white),

                    decoration: _inputDecoration(
                      "Enter Subcategory Name",
                      Icons.edit_outlined,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                /// BUTTON
                SizedBox(
                  height: 56,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,

                      padding: const EdgeInsets.symmetric(horizontal: 28),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: isLoading ? null : handleSubmit,

                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            eid == 0 ? "Save" : "Update",

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TABLE CARD =================
  Widget _buildTableCard() {
    return Card(
      elevation: 20,
      color: const Color(0xff111827),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Subcategory List",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Manage all available subcategories",
                      style: TextStyle(color: Color(0xff9CA3AF), fontSize: 13),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Text(
                    "${subcategoryList.length} Items",

                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// TABLE
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff1F2937),

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: Colors.white.withOpacity(.05)),
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),

                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: DataTable(
                    headingRowHeight: 60,
                    dataRowMinHeight: 65,
                    dataRowMaxHeight: 70,
                    columnSpacing: 275,

                    dividerThickness: .5,

                    headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => const Color(0xff111827),
                    ),

                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => const Color(0xff1F2937),
                    ),

                    columns: const [
                      DataColumn(
                        label: Text(
                          "Sl.No",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      DataColumn(
                        label: Text(
                          "Category",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      DataColumn(
                        label: Text(
                          "Subcategory",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      DataColumn(
                        label: Text(
                          "Actions",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    rows: subcategoryList.asMap().entries.map((entry) {
                      final index = entry.key + 1;

                      final data = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              index.toString(),

                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          DataCell(
                            Text(
                              data['tbl_category']?['category_name'] ?? '',

                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              data['subcategory_name'] ?? '',

                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          DataCell(
                            Row(
                              children: [
                                /// EDIT
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(.15),

                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        eid = data['subcategory_id'];

                                        subcategoryController.text =
                                            data['subcategory_name'];

                                        _selectedvalue = data['category_id']
                                            .toString();
                                      });
                                    },

                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// DELETE
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(.15),

                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: IconButton(
                                    onPressed: () {
                                      _confirmDelete(data['subcategory_id']);
                                    },

                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= INPUT =================
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xff94A3B8)),

      prefixIcon: Icon(icon, color: primary),

      filled: true,
      fillColor: const Color(0xff1E293B),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: Colors.white.withOpacity(.05)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  /// ================= DELETE DIALOG =================
  void _confirmDelete(int id) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            "Delete Subcategory?",
            style: TextStyle(color: Colors.white),
          ),

          content: const Text(
            "This action cannot be undone.",
            style: TextStyle(color: Color(0xffCBD5E1)),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () {
                deleteSubcategory(id);

                Navigator.pop(context);
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
}
