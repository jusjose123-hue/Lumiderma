import 'package:flutter/material.dart';
import 'package:userapp/addproduct.dart';
import 'package:userapp/booking_list.dart';
import 'package:userapp/category.dart';
import 'package:userapp/dermatologist_list.dart';
import 'package:userapp/district.dart';
import 'package:userapp/gallery.dart';
import 'package:userapp/heat_absorption.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/homepage.dart';
import 'package:userapp/myproducts.dart';
import 'package:userapp/place.dart';
import 'package:userapp/registration.dart';
import 'package:userapp/reply.dart';
import 'package:userapp/splash.dart';
import 'package:userapp/stock.dart';
import 'package:userapp/subcategory.dart';
import 'package:userapp/type.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:userapp/userlist.dart';
import 'package:userapp/view_complaints.dart';
import 'package:userapp/welcom.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://zkohpbppnkpdyulqtbev.supabase.co',
    anonKey: 'sb_publishable_DUlRTleIhNOBI0MeNKkvRw_dBPfSdoE',
  );
  runApp(MainApp());
}
final supabase =Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Dashboard',
      home:  SplashScreen(),
    );
  }
}
