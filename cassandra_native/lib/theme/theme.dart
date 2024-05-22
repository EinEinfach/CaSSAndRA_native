import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.grey.shade400,
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