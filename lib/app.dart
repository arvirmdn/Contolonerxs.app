import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';

class ContolonerxsApp extends StatelessWidget {
  const ContolonerxsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contolonerxs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFF1A1B25),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const SplashPage(),
    );
  }
}
