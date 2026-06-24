import 'package:flutter/material.dart';
import 'package:gallery_by_osolution/splash_screen.dart';

import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery by OSol',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorSchemeSeed: Colors.white54,
        brightness: Brightness.dark,
       // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:ModernSplashScreen()
    );
  }
}

