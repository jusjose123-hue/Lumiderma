import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  TextEditingController placeController = TextEditingController();

  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> placeList = [];

  String? selectedDistrict;

  int editId = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDistrict();
    fetchPlace();
  }

  /// ================= FETCH DISTRICT =================

  Future<void> fetchDistrict() async {
    try {
      final response = await supabase.from('tbl_district').select();

      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);

        if (districtList.isNotEmpty) {
          selectedDistrict = districtList.first['district_id'].toString();
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// ================= FETCH PLACE =================

  Future<void> fetchPlace() async {
    try {
      final response = await supabase
          .from('tbl_place')
          .select('*,tbl_district(district_name)');

      setState(() {
        placeList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// ================= INSERT =================

  Future<void> insertPlace() async {
    try {
      setState(() {
        isLoading = true;
      });

      await supabase.from('tbl_place').insert({
        'place_name': placeController.text.trim(),
        'district_id': selectedDistrict,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Place Added Successfully"),
        ),
      );

      placeController.clear();

      fetchPlace();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= UPDATE =================

  Future<void> updatePlace() async {
    try {
      setState(() {
        isLoading = true;
      });

      await supabase
          .from('tbl_place')
          .update({
            'place_name': placeController.text.trim(),
            'district_id': selectedDistrict,
          })
          .eq('place_id', editId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Updated Successfully"),
        ),
      );

      setState(() {
        editId = 0;
      });

      placeController.clear();

      fetchPlace();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= DELETE =================

  Future<void> deletePlace(int id) async {
    try {
      await supabase.from('tbl_place').delete().eq('place_id', id);

      fetchPlace();

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
    placeController.dispose();
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
                        "Place Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Manage places and districts",
                        style: TextStyle(
                          color: Color(0xff94A3B8),
                          fontSize: 13,
                        ),
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
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Text(
                      "${placeList.length} Places",
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
                    /// PLACE FIELD
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: placeController,

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Enter place name",

                          hintStyle: const TextStyle(color: Color(0xff64748B)),

                          prefixIcon: const Icon(
                            Icons.location_on,
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

                    /// DISTRICT DROPDOWN
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedDistrict,

                        dropdownColor: const Color(0xff1E293B),

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          filled: true,

                          fillColor: const Color(0xff111827),

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
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

                        items: districtList.map((district) {
                          return DropdownMenuItem<String>(
                            value: district['district_id'].toString(),

                            child: Text(district['district_name']),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedDistrict = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 18),

                    /// BUTTON
                    SizedBox(
                      height: 56,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (placeController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter place"),
                              ),
                            );

                            return;
                          }

                          if (editId == 0) {
                            insertPlace();
                          } else {
                            updatePlace();
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

                        label: Text(editId == 0 ? "Add Place" : "Update"),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8B5CF6),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          padding: const EdgeInsets.symmetric(horizontal: 22),

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

              /// ================= TABLE =================
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
                        "Place List",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: placeList.isEmpty
                            ? const Center(
                                child: Text(
                                  "No Places Found",
                                  style: TextStyle(color: Color(0xff94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: placeList.length,

                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withOpacity(.05),
                                ),

                                itemBuilder: (context, index) {
                                  final place = placeList[index];

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

                                        /// PLACE DETAILS
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              Text(
                                                place['place_name'] ?? "",

                                                style: const TextStyle(
                                                  color: Colors.white,

                                                  fontSize: 15,

                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                place['tbl_district']?['district_name'] ??
                                                    "",

                                                style: const TextStyle(
                                                  color: Color(0xff94A3B8),

                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// EDIT
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              editId = place['place_id'];

                                              placeController.text =
                                                  place['place_name'];

                                              selectedDistrict =
                                                  place['district_id']
                                                      .toString();
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
                                            deletePlace(place['place_id']);
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
