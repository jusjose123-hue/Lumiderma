import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class HeatAbsorption extends StatefulWidget {
  const HeatAbsorption({super.key});

  @override
  State<HeatAbsorption> createState() => _HeatAbsorptionState();
}

class _HeatAbsorptionState extends State<HeatAbsorption> {
  /// ================= CONTROLLER =================
  final TextEditingController heatController = TextEditingController();

  /// ================= DATA =================
  List<Map<String, dynamic>> heatList = [];

  int editId = 0;

  bool isLoading = false;

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchHeatAbsorption();
  }

  /// ================= FETCH =================
  Future<void> fetchHeatAbsorption() async {
    try {
      final response = await supabase
          .from('tbl_heatabsorption')
          .select()
          .order('heatabsorption_id');

      setState(() {
        heatList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Fetch Error : $e");
    }
  }

  /// ================= INSERT =================
  Future<void> insertHeatAbsorption() async {
    try {
      final heatData = heatController.text.trim();

      if (heatData.isEmpty) {
        _showSnack("Please enter value", Colors.red);
        return;
      }

      setState(() {
        isLoading = true;
      });

      await supabase.from('tbl_heatabsorption').insert({
        'heatabsorption_name': heatData,
      });

      _showSnack("Inserted Successfully", Colors.green);

      heatController.clear();

      fetchHeatAbsorption();
    } catch (e) {
      debugPrint("Insert Error : $e");

      _showSnack("Insert Failed", Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= UPDATE =================
  Future<void> updateHeatAbsorption() async {
    try {
      final heatData = heatController.text.trim();

      if (heatData.isEmpty) {
        _showSnack("Please enter value", Colors.red);
        return;
      }

      setState(() {
        isLoading = true;
      });

      await supabase
          .from('tbl_heatabsorption')
          .update({'heatabsorption_name': heatData})
          .eq('heatabsorption_id', editId);

      _showSnack("Updated Successfully", Colors.green);

      setState(() {
        editId = 0;
      });

      heatController.clear();

      fetchHeatAbsorption();
    } catch (e) {
      debugPrint("Update Error : $e");

      _showSnack("Update Failed", Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= DELETE =================
  Future<void> deleteHeatAbsorption(int id) async {
    try {
      await supabase
          .from('tbl_heatabsorption')
          .delete()
          .eq('heatabsorption_id', id);

      fetchHeatAbsorption();

      _showSnack("Deleted Successfully", Colors.red);
    } catch (e) {
      debugPrint("Delete Error : $e");
    }
  }

  /// ================= SNACKBAR =================
  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  /// ================= DELETE DIALOG =================
  Future<void> _confirmDelete(int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Delete", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Are you sure you want to delete this item?",
            style: TextStyle(color: Colors.white70),
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
              onPressed: () async {
                Navigator.pop(context);
                await deleteHeatAbsorption(id);
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

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),

            margin: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Heat Absorption",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "Manage heat absorption levels",
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        "${heatList.length} Items",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// ================= TOP CARD =================
                Container(
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: const Color(0xff111827),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: heatController,
                              style: const TextStyle(color: Colors.white),

                              decoration: InputDecoration(
                                hintText: "Enter Heat Absorption",

                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),

                                prefixIcon: const Icon(
                                  Icons.thermostat,
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
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          SizedBox(
                            height: 55,

                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff8B5CF6),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),

                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (editId == 0) {
                                        insertHeatAbsorption();
                                      } else {
                                        updateHeatAbsorption();
                                      }
                                    },

                              icon: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      editId == 0 ? Icons.add : Icons.edit,
                                      color: Colors.white,
                                    ),

                              label: Text(
                                editId == 0 ? "Add Item" : "Update Item",

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// ================= TABLE =================
                Expanded(
                  child: Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: const Color(0xff111827),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),

                    child: heatList.isEmpty
                        ? const Center(
                            child: Text(
                              "No Data Found",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 270,
                              horizontalMargin: 20,
                              headingRowHeight: 60,
                              dataRowMinHeight: 65,
                              dataRowMaxHeight: 65,

                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => const Color(0xff1E293B),
                              ),

                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text(
                                      "Sl.No",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                DataColumn(
                                  label: SizedBox(
                                    width: 300,
                                    child: Text(
                                      "Heat Absorption",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                DataColumn(
                                  label: SizedBox(
                                    width: 200,
                                    child: Text(
                                      "Actions",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              rows: heatList.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final data = entry.value;

                                return DataRow(
                                  color:
                                      WidgetStateProperty.resolveWith<Color?>(
                                        (states) => const Color(0xff111827),
                                      ),

                                  cells: [
                                    /// SL NO
                                    DataCell(
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          index.toString(),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// HEAT ABSORPTION
                                    DataCell(
                                      SizedBox(
                                        width: 300,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xff1E293B),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            data['heatabsorption_name'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// ACTIONS
                                    DataCell(
                                      SizedBox(
                                        width: 140,
                                        child: Row(
                                          children: [
                                            /// EDIT
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    editId =
                                                        data['heatabsorption_id'];

                                                    heatController.text =
                                                        data['heatabsorption_name'];
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            /// DELETE
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  _confirmDelete(
                                                    data['heatabsorption_id'],
                                                  );
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
        ),
      ),
    );
  }
}
