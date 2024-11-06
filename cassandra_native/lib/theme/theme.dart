import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
      surface: Colors.grey.shade200,
      primary: Colors.grey.shade400,
      secondary: Colors.grey.shade300,
      onSurface: Colors.grey.shade900,
      onPrimary: Colors.white,
      inversePrimary: Colors.grey.shade800,
      errorContainer: Colors.deepOrange),
  fontFamily: GoogleFonts.montserrat().fontFamily,
  textTheme: const TextTheme(
    bodySmall: TextStyle(
      fontSize: 8,
    ),
    bodyMedium: TextStyle(
      fontSize: 10,
    ),
    labelLarge: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
      surface: Colors.grey.shade800,
      primary: Colors.grey.shade500,
      secondary: Colors.grey.shade600,
      onSurface: Colors.grey.shade100,
      onPrimary: Colors.grey.shade900,
      inversePrimary: Colors.grey.shade200,
      errorContainer: Colors.deepOrange),
  fontFamily: GoogleFonts.montserrat().fontFamily,
  textTheme: const TextTheme(
    bodySmall: TextStyle(
      fontSize: 8,
    ),
    bodyMedium: TextStyle(
      fontSize: 10,
    ),
    labelLarge: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
  ),
);

class PreviewColorPalette {
  List<Color> colors = [
    Colors.blue.shade400,
    Colors.blue.shade800,
    Colors.cyan.shade600,
    Colors.cyan.shade900,
    Colors.purple.shade300,
    Colors.purple.shade600,
  ];
}

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

