import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:userapp/main.dart';

class ProductGallery extends StatefulWidget {
  final String productId;

  const ProductGallery({super.key, required this.productId});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  List<Map<String, dynamic>> _galleryImages = [];
  List<PlatformFile> _selectedFiles = [];

  bool _isUploading = false;
  bool _isLoading = true;

  final Color bgColor = const Color(0xff0B0F1A);
  final Color cardColor = const Color(0xff141B2D);
  final Color primaryColor = const Color(0xff5B8CFF);
  final Color secondaryColor = const Color(0xff7C4DFF);

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  Future<void> fetchGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await supabase
          .from('tbl_gallery')
          .select()
          .eq('product_id', widget.productId);

      setState(() {
        _galleryImages = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint(e.toString());

      _showSnackBar("Failed to load gallery", Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// ================= PICK IMAGES =================

  Future<void> pickImages() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// ================= UPLOAD =================

  Future<void> uploadAndSave() async {
    if (_selectedFiles.isEmpty) {
      _showSnackBar("Please select images", Colors.orange);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      for (var file in _selectedFiles) {
        if (file.bytes == null) continue;

        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

        final path = "gallery/${widget.productId}/$fileName";

        await supabase.storage
            .from('Product')
            .uploadBinary(
              path,
              file.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        final imageUrl = supabase.storage.from('Product').getPublicUrl(path);

        await supabase.from('tbl_gallery').insert({
          'gallery_file': imageUrl,
          'product_id': widget.productId,
        });
      }

      _showSnackBar("Images Uploaded Successfully", Colors.green);

      setState(() {
        _selectedFiles.clear();
      });

      fetchGallery();
    } catch (e) {
      debugPrint(e.toString());

      _showSnackBar(e.toString(), Colors.red);
    }

    setState(() {
      _isUploading = false;
    });
  }

  /// ================= DELETE =================

  Future<void> deleteImage(String galleryId, String imageUrl) async {
    try {
      await supabase.from('tbl_gallery').delete().eq('gallery_id', galleryId);

      _showSnackBar("Image Deleted", Colors.red);

      fetchGallery();
    } catch (e) {
      debugPrint(e.toString());

      _showSnackBar("Delete Failed", Colors.red);
    }
  }

  /// ================= SNACKBAR =================

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 320,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// ICON
                  Container(
                    height: 75,
                    width: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TITLE
                  const Text(
                    "Gallery Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Upload and manage  product gallery images.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// INFO BOX
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          "Product ID",
                          widget.productId,
                          Icons.inventory_2_outlined,
                        ),

                        const SizedBox(height: 18),

                        _infoTile(
                          "Gallery Images",
                          "${_galleryImages.length}",
                          Icons.image_outlined,
                        ),

                        const SizedBox(height: 18),

                        _infoTile(
                          "Selected Files",
                          "${_selectedFiles.length}",
                          Icons.upload_file_rounded,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  /// SELECT BUTTON
                  InkWell(
                    onTap: pickImages,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "SELECT IMAGES",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// UPLOAD BUTTON
                  InkWell(
                    onTap: _isUploading ? null : uploadAndSave,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: _isUploading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "UPLOAD ${_selectedFiles.length} FILES",
                                style: TextStyle(
                                  color: bgColor,
                                  fontWeight: FontWeight.bold,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Product Gallery",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Modern dashboard with live image preview",
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),

                    const SizedBox(height: 25),

                    /// ================= PREVIEW =================
                    if (_selectedFiles.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];

                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 15),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.memory(
                                      file.bytes!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    if (_selectedFiles.isNotEmpty) const SizedBox(height: 25),

                    /// ================= GRID =================
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _galleryImages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 90,
                                    color: Colors.white.withOpacity(0.2),
                                  ),

                                  const SizedBox(height: 20),

                                  Text(
                                    "No Gallery Images",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              itemCount: _galleryImages.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: .88,
                                  ),
                              itemBuilder: (context, index) {
                                final img = _galleryImages[index];

                                return Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(25),
                                                  ),
                                              child: Image.network(
                                                img['gallery_file'],
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),

                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: GestureDetector(
                                                onTap: () {
                                                  deleteImage(
                                                    img['gallery_id']
                                                        .toString(),
                                                    img['gallery_file'],
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.black54,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.image,
                                                color: primaryColor,
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Text(
                                                "Gallery Image ${index + 1}",
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
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

  Widget _infoTile(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
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
