import 'package:dermatologist_app/changepassword.dart';
import 'package:dermatologist_app/editprofile.dart';
import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/login.dart';
import 'package:dermatologist_app/myprofile.dart';
import 'package:dermatologist_app/registration.dart';
import 'package:dermatologist_app/splash.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
   url: 'https://zkohpbppnkpdyulqtbev.supabase.co',
    anonKey: 'sb_publishable_DUlRTleIhNOBI0MeNKkvRw_dBPfSdoE',
  );

  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
     home:  SplashScreen(),
    );
  }
}
