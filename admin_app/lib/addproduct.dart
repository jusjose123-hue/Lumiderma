import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:userapp/main.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({super.key});

  @override
  State<Addproduct> createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  List<Map<String, dynamic>> _skinTypes = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _heatList = [];
  List<Map<String, dynamic>> _levelList = [];

  int? _selectedSkinType;
  int? _selectedCategory;
  int? _selectedHeat;
  int? _selectedLevel;

  PlatformFile? pickedImage;
  Uint8List? imageBytes;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSkinTypes();
    _fetchCategory();
    _fetchHeat();
    _fetchLevel();
  }

  /// ================= FETCH =================

  Future<void> _fetchSkinTypes() async {
    final response = await supabase
        .from('tbl_type')
        .select('type_id,type_name');

    setState(() {
      _skinTypes = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchCategory() async {
    final response = await supabase
        .from('tbl_category')
        .select('category_id,category_name');

    setState(() {
      _categories = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchHeat() async {
    final response = await supabase
        .from('tbl_heatabsorption')
        .select('heatabsorption_id,heatabsorption_name');

    setState(() {
      _heatList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchLevel() async {
    final response = await supabase
        .from('tbl_level')
        .select('level_id,level_name');

    setState(() {
      _levelList = List<Map<String, dynamic>>.from(response);
    });
  }

  /// ================= IMAGE PICK =================

  Future<void> handleImagePick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

  /// ================= PHOTO UPLOAD =================

  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'User';

      final filePath = "product/$uid.${pickedImage!.extension}";

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /// ================= SUBMIT =================

  Future<void> _submitProduct() async {
    try {
      if (nameController.text.trim().isEmpty ||
          priceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name and Price required")),
        );
        return;
      }

      final price = double.tryParse(priceController.text.trim());

      if (price == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Enter valid price")));
        return;
      }

      setState(() {
        isLoading = true;
      });

      String? imageUrl;

      if (imageBytes != null) {
        final uid = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await photoUpload(uid);
      }

      await supabase.from('tbl_product').insert({
        'product_name': nameController.text.trim(),
        'product_description': descriptionController.text.trim(),
        'product_price': price,
        'type_id': _selectedSkinType,
        'category_id': _selectedCategory,
        'heatabsorption_id': _selectedHeat,
        'level_id': _selectedLevel,
        'product_photo': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Product Added Successfully"),
        ),
      );

      _clearForm();
    } catch (e) {
      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= CLEAR =================

  void _clearForm() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();

    setState(() {
      _selectedSkinType = null;
      _selectedCategory = null;
      _selectedHeat = null;
      _selectedLevel = null;
      imageBytes = null;
      pickedImage = null;
    });
  }

  /// ================= UI =================

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= BREADCRUMB =================
            Row(
              children: [
                _breadText("Dashboard"),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xff64748B),
                ),
                const SizedBox(width: 5),
                _breadText("Products"),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xff64748B),
                ),
                const SizedBox(width: 5),
                const Text(
                  "Add new",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Add new product",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Fill in the details to list a product in your catalog.",
                      style: TextStyle(fontSize: 13, color: Color(0xff94A3B8)),
                    ),
                  ],
                ),

                Row(
                  children: [
                    _ghostButton(
                      text: "Discard",
                      icon: Icons.close,
                      onTap: _clearForm,
                    ),

                    const SizedBox(width: 10),

                    _primaryButton(
                      text: "Save product",
                      icon: Icons.check_circle_outline,
                      onTap: _submitProduct,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ================= MAIN LAYOUT =================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    children: [
                      /// BASIC INFO
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("BASIC INFORMATION"),

                            const SizedBox(height: 18),

                            _buildField(
                              label: "Product name",
                              child: _input(
                                controller: nameController,
                                
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildField(
                              label: "Description",
                              child: _input(
                                controller: descriptionController,
                                maxLines: 5,
                                hint:
                                    "Benefits, ingredients, usage instructions…",
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    label: "Price",
                                    child: _priceInput(),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: _buildField(
                                    label: "Category",
                                    child: _dropdown(
                                      value: _selectedCategory,
                                      items: _categories,
                                      idKey: "category_id",
                                      nameKey: "category_name",
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedCategory = v;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// SKIN ATTRIBUTES
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("SKIN ATTRIBUTES"),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    label: "Skin type",
                                    child: _dropdown(
                                      value: _selectedSkinType,
                                      items: _skinTypes,
                                      idKey: "type_id",
                                      nameKey: "type_name",
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedSkinType = v;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: _buildField(
                                    label: "Level indication",
                                    child: _dropdown(
                                      value: _selectedLevel,
                                      items: _levelList,
                                      idKey: "level_id",
                                      nameKey: "level_name",
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedLevel = v;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _buildField(
                              label: "Heat absorption",
                              child: _dropdown(
                                value: _selectedHeat,
                                items: _heatList,
                                idKey: "heatabsorption_id",
                                nameKey: "heatabsorption_name",
                                onChanged: (v) {
                                  setState(() {
                                    _selectedHeat = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                /// RIGHT SIDE
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      /// IMAGE CARD
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("PRODUCT IMAGE"),

                            const SizedBox(height: 18),

                            GestureDetector(
                              onTap: handleImagePick,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                  horizontal: 16,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xff111827),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xff334155),
                                  ),
                                ),

                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 40,
                                      color: Color(0xff8B5CF6),
                                    ),

                                    const SizedBox(height: 10),

                                    const Text(
                                      "Click to upload",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    const Text(
                                      "PNG or JPG, up to 5 MB",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff94A3B8),
                                      ),
                                    ),

                                    if (imageBytes != null) ...[
                                      const SizedBox(height: 16),

                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          imageBytes!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// DETAILS CARD
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("LISTING DETAILS"),

                            const SizedBox(height: 16),

                            _statusRow(
                              "Status",
                              _badge(
                                "Draft",
                                const Color(0xff14532D),
                                const Color(0xffBBF7D0),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _statusRow(
                              "Visibility",
                              const Text(
                                "Public",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _statusRow(
                              "Added by",
                              const Text(
                                "Admin",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Divider(color: Colors.white.withOpacity(.08)),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              child: _primaryButton(
                                text: "Save product",
                                icon: Icons.check_circle_outline,
                                onTap: _submitProduct,
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: _ghostButton(
                                text: "Clear form",
                                icon: Icons.cleaning_services_outlined,
                                onTap: _clearForm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= WIDGETS =================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: Color(0xff94A3B8),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xffCBD5E1),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xff64748B)),
        filled: true,
        fillColor: const Color(0xff111827),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff8B5CF6)),
        ),
      ),
    );
  }

  Widget _priceInput() {
    return TextFormField(
      controller: priceController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixText: "₹ ",
        prefixStyle: const TextStyle(color: Colors.white),
        hintText: "0.00",

        hintStyle: const TextStyle(color: Color(0xff64748B)),

        filled: true,
        fillColor: const Color(0xff111827),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff8B5CF6)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,

      dropdownColor: const Color(0xff1E293B),

      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xff111827),

        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff8B5CF6)),
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item[idKey],
          child: Text(
            item[nameKey],
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xff534AB7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _ghostButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color.fromARGB(255, 242, 243, 247)),
      label: Text(text, style: const TextStyle(color: Color.fromARGB(255, 233, 238, 245))),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _statusRow(String title, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Color(0xff6B7280)),
        ),
        trailing,
      ],
    );
  }

  Widget _badge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _breadText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xff9CA3AF)),
    );
  }
}
