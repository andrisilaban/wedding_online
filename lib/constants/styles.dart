// lib/core/constants/app_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final themeColor = Colors.indigo;

final headingStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: themeColor,
);

final subheadingStyle = GoogleFonts.poppins(
  fontSize: 14,
  color: Colors.grey[600],
);

final buttonTextStyle = GoogleFonts.poppins(fontSize: 16, color: Colors.white);

final inputDecoration = InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);

final formCardPadding = const EdgeInsets.symmetric(
  vertical: 32,
  horizontal: 24,
);
final screenPadding = const EdgeInsets.symmetric(horizontal: 24);
final formFieldSpacing = const SizedBox(height: 16);
final formTopSpacing = const SizedBox(height: 24);
