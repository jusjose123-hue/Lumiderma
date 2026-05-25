import 'package:admin_app/changepassword.dart';
import 'package:admin_app/complaint.dart';
import 'package:admin_app/d.dart';
import 'package:admin_app/editprofile.dart';
import 'package:admin_app/homepage.dart';
import 'package:admin_app/index_page.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/myprofile.dart';
import 'package:admin_app/registration.dart';
import 'package:admin_app/weather.dart';
import 'package:admin_app/welcompage.dart';
import 'package:admin_app/splash.dart'; // Make sure this matches your splash file name
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Required when initializing plugins before runApp
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await Supabase.initialize(
    url: 'https://zkohpbppnkpdyulqtbev.supabase.co',
    anonKey: 'sb_publishable_DUlRTleIhNOBI0MeNKkvRw_dBPfSdoE',
  );
  runApp(const MainApp());
}

// Global supabase instance accessible across your app
final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // This loads your splash screen first!
    );
  }
}