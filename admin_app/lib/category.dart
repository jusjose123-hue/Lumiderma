import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // ================= CONTROLLERS =================
  final TextEditingController categoryController = TextEditingController();

  final ScrollController _verticalController = ScrollController();

  final ScrollController _horizontalController = ScrollController();

  // ================= STATE =================
  List<Map<String, dynamic>> categoryList = [];

  int eid = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  // ================= FETCH =================
  Future<void> fetchCategory() async {
    try {
      final response = await supabase
          .from('tbl_category')
          .select()
          .order('category_id');

      setState(() {
        categoryList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Fetch Error : $e");

      _showSnack("Failed to fetch categories", Colors.red);
    }
  }

  // ================= INSERT / UPDATE =================
  Future<void> handleSubmit() async {
    final categoryData = categoryController.text.trim();

    if (categoryData.isEmpty) {
      _showSnack("Please enter category name", Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // INSERT
      if (eid == 0) {
        await supabase.from('tbl_category').insert({
          'category_name': categoryData,
        });

        _showSnack("Category Added Successfully", Colors.green);
      }
      // UPDATE
      else {
        await supabase
            .from('tbl_category')
            .update({'category_name': categoryData})
            .eq('category_id', eid);

        _showSnack("Category Updated Successfully", Colors.blue);
      }

      resetForm();

      await fetchCategory();
    } catch (e) {
      debugPrint("Submit Error : $e");

      _showSnack(e.toString(), Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= DELETE =================
  Future<void> deleteCategory(int id) async {
    try {
      await supabase.from('tbl_category').delete().eq('category_id', id);

      fetchCategory();

      _showSnack("Category Deleted Successfully", Colors.red);
    } catch (e) {
      debugPrint("Delete Error : $e");

      _showSnack(e.toString(), Colors.red);
    }
  }

  // ================= RESET =================
  void resetForm() {
    setState(() {
      eid = 0;
      categoryController.clear();
    });
  }

  // ================= SNACKBAR =================
  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),

            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _buildHeader(),

                const SizedBox(height: 30),

                _buildFormSection(),

                const SizedBox(height: 30),

                Expanded(child: _buildTableSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Category Management",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Manage your categories easily",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),

        _buildBadge("${categoryList.length} Total"),
      ],
    );
  }

  // ================= BADGE =================
  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

      decoration: BoxDecoration(
        color: const Color(0xff1E293B),

        borderRadius: BorderRadius.circular(30),

        border: Border.all(color: Colors.white10),
      ),

      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= FORM =================
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: const Color(0xff111827),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white10),
      ),

      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: categoryController,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: "Enter category name",

                hintStyle: const TextStyle(color: Colors.white38),

                prefixIcon: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xff8B5CF6),
                ),

                filled: true,

                fillColor: const Color(0xff1E293B),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(
                    color: Color(0xff8B5CF6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          if (eid != 0)
            IconButton(
              onPressed: resetForm,

              icon: const Icon(Icons.close, color: Colors.white54),
            ),

          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ================= SUBMIT BUTTON =================
  Widget _buildSubmitButton() {
    bool isUpdate = eid != 0;

    return SizedBox(
      height: 56,

      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isUpdate ? Colors.blue : const Color(0xff8B5CF6),

          padding: const EdgeInsets.symmetric(horizontal: 28),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        onPressed: isLoading ? null : handleSubmit,

        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(isUpdate ? Icons.edit : Icons.add, color: Colors.white),

        label: Text(
          isUpdate ? "Update" : "Add Category",

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= TABLE =================
  Widget _buildTableSection() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xff111827),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white10),
      ),

      child: categoryList.isEmpty
          ? const Center(
              child: Text(
                "No Categories Found",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(24),

              child: Scrollbar(
                controller: _verticalController,

                child: SingleChildScrollView(
                  controller: _verticalController,

                  child: Scrollbar(
                    controller: _horizontalController,

                    child: SingleChildScrollView(
                      controller: _horizontalController,

                      scrollDirection: Axis.horizontal,

                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48,
                        ),

                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xff1E293B),
                          ),

                          columns: [
                            _buildDataColumn("SL.NO"),

                            _buildDataColumn("CATEGORY NAME"),

                            _buildDataColumn("ACTIONS"),
                          ],

                          rows: categoryList.asMap().entries.map((entry) {
                            final index = entry.key + 1;

                            final category = entry.value;

                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                return index.isEven
                                    ? Colors.white.withOpacity(0.02)
                                    : Colors.transparent;
                              }),

                              cells: [
                                DataCell(
                                  Text(
                                    index.toString(),

                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),

                                DataCell(
                                  Text(
                                    category['category_name'] ?? '',

                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),

                                DataCell(_buildActionButtons(category)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ================= DATACOLUMN =================
  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,

        style: const TextStyle(
          color: Color(0xff8B5CF6),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons(Map<String, dynamic> category) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        // EDIT
        _tableIconButton(
          icon: Icons.edit_outlined,

          color: Colors.blueAccent,

          onPressed: () {
            setState(() {
              eid = int.parse(category['category_id'].toString());

              categoryController.text = category['category_name'];
            });
          },
        ),

        const SizedBox(width: 8),

        // DELETE
        _tableIconButton(
          icon: Icons.delete_outline_rounded,

          color: Colors.redAccent,

          onPressed: () {
            _confirmDelete(int.parse(category['category_id'].toString()));
          },
        ),
      ],
    );
  }

  // ================= ICON BUTTON =================
  Widget _tableIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius: BorderRadius.circular(8),
      ),

      child: IconButton(
        iconSize: 20,

        visualDensity: VisualDensity.compact,

        icon: Icon(icon, color: color),

        onPressed: onPressed,
      ),
    );
  }

  // ================= DELETE CONFIRM =================
  Future<void> _confirmDelete(int id) async {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E293B),

          title: const Text(
            "Confirm Delete",
            style: TextStyle(color: Colors.white),
          ),

          content: const Text(
            "Are you sure you want to delete this category?",
            style: TextStyle(color: Colors.white70),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () async {
                Navigator.pop(context);

                await deleteCategory(id);
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    categoryController.dispose();

    _verticalController.dispose();

    _horizontalController.dispose();

    super.dispose();
  }
}
