import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:userapp/main.dart';
import 'dart:io' show Directory, File, Platform; // Ensure these are imported at the top
import 'package:path/path.dart' as p;            // Helps handle windows path backslashes cleanly
import 'package:path_provider/path_provider.dart'; 
import 'package:dio/dio.dart';

class DermaList extends StatefulWidget {
  const DermaList({super.key});

  @override
  State<DermaList> createState() => _DermaListState();
}

class _DermaListState extends State<DermaList> {
  static const Color bgColor = Color(0xff0F172A);
  static const Color cardColor = Color(0xff1E293B);
  static const Color accentColor = Color(0xff8B5CF6);
  static const Color subTextColor = Color(0xff94A3B8);

  List<Map<String, dynamic>> _dermatologists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDermatologists();
  }

  Future<void> fetchDermatologists() async {
    try {
      final response = await supabase.from('tbl_dermatologist').select();
      setState(() {
        _dermatologists = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Real File Downloader Implementation
  Future<void> _downloadProof(String? urlString, String doctorName) async {
  if (urlString == null || urlString.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No proof file available to download.')),
      );
    }
    return;
  }

  // 1. Sanitize the filename to remove characters illegal in Windows file systems
  final safeDoctorName = doctorName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').replaceAll(' ', '_');
  
  // Extract original extension from the URL (defaults to pdf if none found)
  final uriPath = Uri.parse(urlString).path;
  final extension = p.extension(uriPath).isNotEmpty ? p.extension(uriPath) : '.pdf';
  final fileName = "${safeDoctorName}_Proof$extension";

  // 2. Handle Windows Desktop Architecture Directly
  if (!kIsWeb && Platform.isWindows) {
    try {
      // Safely gets the actual 'C:\Users\username\Downloads' system folder
      final Directory? downloadsDir = await getDownloadsDirectory();
      
      if (downloadsDir == null) {
        throw "Could not access system Downloads directory.";
      }

      final String fullSavePath = p.join(downloadsDir.path, fileName);

      // Show a temporary "Downloading..." indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading file to system Downloads folder...'), duration: const Duration(seconds: 1)),
        );
      }

      // Stream data chunks via Dio and write natively to file storage
      final dio = Dio();
      await dio.download(
        urlString.trim(),
        fullSavePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Windows localized download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } 
  // 3. Fallback/Mobile/Web environment handling
  else {
    // Keep your web/mobile implementation block here unchanged
    final Uri url = Uri.parse(urlString.trim());
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirected to file download link.'), backgroundColor: Colors.green),
        );
      }
    }
  }
}

  /// Interactive Proof Viewer Modal (Supports both Images and Documents)
  Future<void> _viewProofDialog(String? urlString, String doctorName) async {
    if (urlString == null || urlString.isEmpty) return;

    // Clean URL query parameters to accurately check the extension
    final cleanUrl = urlString.split('?').first.toLowerCase();
    final isImage = cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png');

    if (isImage) {
      // Show native modal image view with gesture zoom
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            height: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "$doctorName - Proof Document",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        urlString,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: accentColor),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              "Failed to display image proof format.",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text("Download Original File"),
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadProof(urlString, doctorName);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // If it's a PDF/Document format, open via System Browser or App viewer directly
      try {
        final Uri url = Uri.parse(urlString);
        if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening document proof natively...')),
            );
          }
        } else {
          throw 'Could not launch file stream';
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening document: $e"),
            backgroundColor: const Color(0xffEF4444),
          ),
        );
      }
    }
  }

  Future<void> updateStatus(dynamic id, String status) async {
    try {
      await supabase
          .from('tbl_dermatologist')
          .update({'dermatologist_status': status})
          .eq('dermatologist_id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as ${status.toUpperCase()}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      fetchDermatologists();
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _dermatologists
        .where((d) => d['dermatologist_status'] == null || d['dermatologist_status'] == 'pending')
        .toList();
    
    final approvedList = _dermatologists
        .where((d) => d['dermatologist_status'] == 'approved')
        .toList();

    final rejectedList = _dermatologists
        .where((d) => d['dermatologist_status'] == 'rejected')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TabBar(
                isScrollable: true,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.white38,
                tabs: const [
                  Tab(text: "PENDING"),
                  Tab(text: "APPROVED"),
                  Tab(text: "REJECTED"),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: accentColor))
                  : TabBarView(
                      children: [
                        _buildTableContainer(pendingList, "pending"),
                        _buildTableContainer(approvedList, "approved"),
                        _buildTableContainer(rejectedList, "rejected"),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableContainer(List<Map<String, dynamic>> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No $type dermatologists found.",
          style: const TextStyle(color: Colors.white24, fontSize: 16),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: _buildDataTable(data),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text(
          "Management Panel",
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

  Widget _buildDataTable(List<Map<String, dynamic>> list) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.03)),
          dataRowMaxHeight: 70,
          columns: const [
            DataColumn(label: Text("SL.NO", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("PHOTO", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("NAME", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("EMAIL", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("EXPERIENCE", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("SPECIALIZATION", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("PROOF", style: TextStyle(color: accentColor, fontSize: 12))),
            DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontSize: 12))),
          ],
          rows: list.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final derma = entry.value;
            final currentStatus = derma['dermatologist_status'];
            final proofUrl = derma['dermatologist_proof'];
            final docName = derma['dermatologist_name'] ?? 'unknown';

            // Checking the file extension pattern for preview
            final String cleanUrl = (proofUrl ?? '').split('?').first.toLowerCase();
            final bool isImage = cleanUrl.endsWith('.jpg') || cleanUrl.endsWith('.jpeg') || cleanUrl.endsWith('.png');

            return DataRow(cells: [
              DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
              DataCell(CircleAvatar(
                backgroundImage: (derma['dermatologist_photo'] != null && derma['dermatologist_photo'] != '')
                    ? NetworkImage(derma['dermatologist_photo'])
                    : null,
              )),
              DataCell(Text(docName, style: const TextStyle(color: Colors.white))),
              DataCell(Text(derma['dermatologist_email'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
              DataCell(Text(derma['dermatologist_experience'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
              // Fixed spelling matching schema structure:
              DataCell(Text(derma['dermatologist_specilization'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
              
              // Updated PROOF Column
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _viewProofDialog(proofUrl, docName), 
                      child: Tooltip(
                        message: isImage ? "Click to View Image" : "Click to Open Document",
                        child: CircleAvatar(
                          backgroundColor: Colors.white10,
                          backgroundImage: (proofUrl != null && proofUrl != '' && isImage)
                              ? NetworkImage(proofUrl)
                              : null,
                          child: (proofUrl == null || proofUrl == '')
                              ? const Icon(Icons.block, size: 16, color: Colors.white24)
                              : (!isImage 
                                  ? const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.redAccent)
                                  : null),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (proofUrl != null && proofUrl != '')
                      IconButton(
                        tooltip: "Download to local system",
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.blueAccent, size: 22),
                        onPressed: () => _downloadProof(proofUrl, docName),
                      )
                    else
                      const Text("No File", style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
              
              DataCell(
                Row(
                  children: [
                    if (currentStatus != 'approved')
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                        onPressed: () => updateStatus(derma['dermatologist_id'], 'approved'),
                      ),
                    if (currentStatus != 'rejected')
                      IconButton(
                        icon: const Icon(Icons.highlight_off, color: Colors.redAccent, size: 20),
                        onPressed: () => updateStatus(derma['dermatologist_id'], 'rejected'),
                      ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}