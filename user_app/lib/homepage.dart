import 'package:admin_app/main.dart';
import 'package:admin_app/p.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/d.dart';
import 'package:admin_app/docdetail.dart';
import 'package:admin_app/mkdata.dart';
import 'package:admin_app/prodetail.dart';
import 'package:admin_app/weather.dart';
import 'package:admin_app/wedata.dart';
import 'package:admin_app/doc_Mockdata.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String name = "";
  String address = "";

  List<Map<String, dynamic>> dermatologistList = [];
  List<Map<String, dynamic>> productList = [];

  bool isLoading = true;

  /// FETCH USER
  Future<void> fetchuser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        name = response['user_name']?.toString() ?? "";
        address = response['user_address']?.toString() ?? "";
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  /// FETCH DOCTORS
  Future<void> fetchdermatologist() async {
    try {
      final response = await supabase.from('tbl_dermatologist').select();

      setState(() {
        dermatologistList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching dermatologist: $e");
    }
  }

  /// FETCH PRODUCTS
  Future<void> fetchproduct() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select(
            '*, tbl_category(category_name), tbl_type(type_name), tbl_heatabsorption(heatabsorption_name)',
          );

      setState(() {
        productList = List<Map<String, dynamic>>.from(response);

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");

      setState(() {
        isLoading = false;
      });
    }
  }
  @override
void initState() {
  super.initState();

  fetchuser();
  fetchdermatologist();
  fetchproduct();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 67, 22, 130),
              const Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topRight,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${name.isEmpty ? 'User' : name} 👋",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "UV Sense",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(147, 68, 79, 85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white),
                            Text(
                              address.isEmpty ? "No Address" : address,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // 🔹 UV Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(186, 155, 39, 176),
                          const Color.fromARGB(255, 80, 40, 148),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "33.71°C",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "UV Extreme • Index 14",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.warning, color: Colors.yellow, size: 40),
                      ],
                    ),
                  ),

                  SizedBox(height: 35),

                  // 🔹 Risk Bar
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(51, 214, 214, 214),
                          const Color.fromARGB(102, 49, 6, 78),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔸 Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "UV Exposure Risk",
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              "Extreme",
                              style: TextStyle(color: Colors.pink),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // 🔸 Rounded Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 1,
                            minHeight: 10,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.pinkAccent,
                            ),
                          ),
                        ),

                        SizedBox(height: 10),

                        // 🔸 Labels (same as UI)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Low",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Moderate",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "High",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Very High",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Extreme",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 35),

                  // 🔹 Weather Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Weather(we: we[0]),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: AssetImage("assets/w.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 35),

                  // 🔥 MAIN WRAPPER CARD
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(140, 35, 4, 55),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        // 🟣 AI Skin Care Log
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              "AI Skin Care Log",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        // 🔸 Skin Tips
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.spa, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Skin Tips",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                "• Seek immediate shade",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "• Cover all exposed skin",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "• Limit outdoor activity",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 25),

                        // 🟣 Products
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(139, 5, 0, 7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.pink,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Recommended Products",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(width: 26,),
                                  TextButton(onPressed: (){
                                     Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                               Products(),
                                          ),
                                        );
                                  }, child: Text("View All",style: TextStyle(fontWeight:FontWeight.bold,
                              fontSize: 10,color: const Color.fromARGB(163, 233, 30, 98)),)),
                                  
                                ],
                              ),
                            

                              SizedBox(height: 10),

                              /// PRODUCTS
                              SizedBox(
                                height: 190,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: productList.length,
                                  itemBuilder: (context, index) {
                                    final item = productList[index];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Productdetails(mkdata: item),
                                          ),
                                        );
                                      },

                                      child: Container(
                                        width: 160,
                                        margin: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            /// 🔵 PRODUCT IMAGE (CIRCLE AVATAR STYLE)
                                            Center(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.pinkAccent,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.pink
                                                          .withOpacity(0.3),
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                                child: CircleAvatar(
                                                  radius: 38,
                                                  backgroundImage: NetworkImage(
                                                    item['product_photo'] ?? '',
                                                  ),
                                                  backgroundColor:
                                                      Colors.grey[800],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            Text(
                                              item['product_name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            /// 💰 PRICE
                                            Text(
                                              "₹${item['product_price'] ?? ''}",
                                              style: const TextStyle(
                                                color: Colors.pinkAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 25),

                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Header with icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.pink,
                                    size: 22,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Doctors",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10),

                              // 🔸 Horizontal list
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: dermatologistList.length,
                                  itemBuilder: (context, index) {
                                    final doc = dermatologistList[index];

                                    return Container(
                                      width: 150,
                                      margin: EdgeInsets.only(right: 15),
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 35,
                                            backgroundImage: NetworkImage(
                                              doc['dermatologist_photo'] ?? '',
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            doc['dermatologist_name'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            doc['dermatologist_specilization'],
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Docdetail(doc: doc),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              "View",
                                              style: TextStyle(
                                                color: Colors.pink,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
