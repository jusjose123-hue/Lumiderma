import 'package:flutter/material.dart';
import 'package:userapp/main.dart';

class Level extends StatefulWidget {
  const Level({super.key});

  @override
  State<Level> createState() => _LevelState();
}

class _LevelState extends State<Level> {
  TextEditingController levelController = TextEditingController();

  List<Map<String, dynamic>> levelList = [];

  int editId = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchlevel();
  }

  /// ================= FETCH =================

  Future<void> fetchlevel() async {
    try {
      final response = await supabase.from('tbl_level').select();

      setState(() {
        levelList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  /// ================= INSERT =================

  Future<void> insertlevel() async {
    try {
      setState(() {
        isLoading = true;
      });

      final levelData = levelController.text.trim();

      await supabase.from('tbl_level').insert({'level_name': levelData});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("$levelData Added Successfully"),
        ),
      );

      levelController.clear();

      fetchlevel();
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

  /// ================= UPDATE =================

  Future<void> updatelevel() async {
    try {
      setState(() {
        isLoading = true;
      });

      await supabase
          .from('tbl_level')
          .update({'level_name': levelController.text.trim()})
          .eq('level_id', editId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Updated Successfully"),
        ),
      );

      setState(() {
        editId = 0;
      });

      levelController.clear();

      fetchlevel();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= DELETE =================

  Future<void> deletelevel(int id) async {
    try {
      await supabase.from('tbl_level').delete().eq('level_id', id);

      fetchlevel();

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
    levelController.dispose();
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
                        "Level Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Manage all product levels from here",
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
                      "${levelList.length} Levels",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// ================= INPUT CARD =================
              Container(
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: const Color(0xff1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.05)),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: levelController,

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Enter level name",

                          hintStyle: const TextStyle(color: Color(0xff64748B)),

                          prefixIcon: const Icon(
                            Icons.layers_rounded,
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

                    SizedBox(
                      height: 56,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (levelController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter level"),
                              ),
                            );
                            return;
                          }

                          if (editId == 0) {
                            insertlevel();
                          } else {
                            updatelevel();
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

                        label: Text(editId == 0 ? "Add Level" : "Update Level"),

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

              /// ================= TABLE CARD =================
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
                        "Level List",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: levelList.isEmpty
                            ? const Center(
                                child: Text(
                                  "No Levels Found",
                                  style: TextStyle(color: Color(0xff94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: levelList.length,

                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withOpacity(.05),
                                ),

                                itemBuilder: (context, index) {
                                  final data = levelList[index];

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
                                        /// INDEX
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

                                        /// LEVEL NAME
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['level_name'] ?? "",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              const Text(
                                                "Product Level",
                                                style: TextStyle(
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
                                              editId = data['level_id'];

                                              levelController.text =
                                                  data['level_name'];
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
                                            deletelevel(data['level_id']);
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
