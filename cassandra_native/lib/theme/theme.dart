import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: const Color.fromARGB(255, 165, 245, 238),
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade200,
    onBackground: Colors.grey.shade900,
    
  ),
  fontFamily: GoogleFonts.montserrat().fontFamily,
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: Colors.grey.shade900,
    primary: Colors.grey.shade700,
    secondary: Colors.grey.shade600,
    onBackground: Colors.grey.shade100,
  ),
  fontFamily: GoogleFonts.montserrat().fontFamily,
);

// var lightColorScheme = ColorScheme.fromSeed(
//   brightness: Brightness.light,
//   seedColor: const Color.fromARGB(255, 17, 243, 243),
// );

// var darkColorScheme = ColorScheme.fromSeed(
//   brightness: Brightness.dark,
//   seedColor: const Color.fromARGB(0, 32, 32, 32),
// );

// ThemeData lightMode = ThemeData(
//   colorScheme: lightColorScheme,
//   fontFamily: GoogleFonts.montserrat().fontFamily,
// );

// ThemeData darkMode = ThemeData(
//   colorScheme: darkColorScheme,
//   fontFamily: GoogleFonts.montserrat().fontFamily,
// );

