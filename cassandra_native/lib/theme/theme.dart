import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade200,
    primary: Colors.grey.shade400,
    secondary: Colors.grey.shade300,
    onSurface: Colors.grey.shade900,
    inversePrimary: Colors.grey.shade800,
    
  ),
  fontFamily: GoogleFonts.montserrat().fontFamily,
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade800,
    primary: Colors.grey.shade500,
    secondary: Colors.grey.shade400,
    onSurface: Colors.grey.shade100,
    inversePrimary: Colors.grey.shade200,
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

