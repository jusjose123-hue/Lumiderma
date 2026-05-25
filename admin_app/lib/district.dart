import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  TextEditingController districtController = TextEditingController();

  List<Map<String, dynamic>> districtList = [];

  int editId = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDistrict();
  }

  /// ================= FETCH =================

  Future<void> fetchDistrict() async {
    try {
      final response = await supabase.from('tbl_district').select();

      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// ================= INSERT =================

  Future<void> insertDistrict() async {
    try {
      setState(() {
        isLoading = true;
      });

      await supabase.from('tbl_district').insert({
        'district_name': districtController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("District Added Successfully"),
        ),
      );

      districtController.clear();

      fetchDistrict();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= UPDATE =================

  Future<void> updateDistrict() async {
    try {
      setState(() {
        isLoading = true;
      });

      await supabase
          .from('tbl_district')
          .update({'district_name': districtController.text.trim()})
          .eq('district_id', editId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Updated Successfully"),
        ),
      );

      setState(() {
        editId = 0;
      });

      districtController.clear();

      fetchDistrict();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= DELETE =================

  Future<void> deleteDistrict(int id) async {
    try {
      await supabase.from('tbl_district').delete().eq('district_id', id);

      fetchDistrict();

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
    districtController.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "District Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Manage all available districts",
                        style: TextStyle(
                          color: Color(0xff94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xff1E293B),

                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Text(
                      "${districtList.length} Districts",

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// ================= FORM CARD =================
              Container(
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: const Color(0xff1E293B),

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: Colors.white.withOpacity(.05)),
                ),

                child: Row(
                  children: [
                    /// TEXT FIELD
                    Expanded(
                      child: TextFormField(
                        controller: districtController,

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Enter district name",

                          hintStyle: const TextStyle(color: Color(0xff64748B)),

                          prefixIcon: const Icon(
                            Icons.location_city,
                            color: Color(0xff8B5CF6),
                          ),

                          filled: true,

                          fillColor: const Color(0xff111827),

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(.05),
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: const BorderSide(
                              color: Color(0xff8B5CF6),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    /// BUTTON
                    SizedBox(
                      height: 56,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (districtController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please Enter District"),
                              ),
                            );

                            return;
                          }

                          if (editId == 0) {
                            insertDistrict();
                          } else {
                            updateDistrict();
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
                            : Icon(editId == 0 ? Icons.add : Icons.edit),

                        label: Text(editId == 0 ? "Add District" : "Update"),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8B5CF6),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          padding: const EdgeInsets.symmetric(horizontal: 24),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ================= LIST =================
              Expanded(
                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: const Color(0xff1E293B),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: Colors.white.withOpacity(.05)),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "District List",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: districtList.isEmpty
                            ? const Center(
                                child: Text(
                                  "No Districts Found",
                                  style: TextStyle(color: Color(0xff94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: districtList.length,

                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withOpacity(.05),
                                ),

                                itemBuilder: (context, index) {
                                  final district = districtList[index];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),

                                    decoration: BoxDecoration(
                                      color: const Color(0xff111827),

                                      borderRadius: BorderRadius.circular(16),
                                    ),

                                    child: Row(
                                      children: [
                                        /// NUMBER
                                        Container(
                                          height: 42,
                                          width: 42,

                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xff8B5CF6,
                                            ).withOpacity(.15),

                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),

                                          child: Center(
                                            child: Text(
                                              "${index + 1}",

                                              style: const TextStyle(
                                                color: Color(0xffC4B5FD),

                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        /// DISTRICT NAME
                                        Expanded(
                                          child: Text(
                                            district['district_name'] ?? "",

                                            style: const TextStyle(
                                              color: Colors.white,

                                              fontSize: 15,

                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),

                                        /// EDIT
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              editId = district['district_id'];

                                              districtController.text =
                                                  district['district_name'];
                                            });
                                          },

                                          icon: const Icon(
                                            Icons.edit_outlined,

                                            color: Color(0xff38BDF8),
                                          ),
                                        ),

                                        /// DELETE
                                        IconButton(
                                          onPressed: () {
                                            deleteDistrict(
                                              district['district_id'],
                                            );
                                          },

                                          icon: const Icon(
                                            Icons.delete_outline,

                                            color: Colors.redAccent,
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
      ),
    );
  }
}
