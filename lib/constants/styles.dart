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

final TextStyle headerTextStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.purple.shade700,
);

final TextStyle bodyTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  color: Colors.grey.shade700,
);

final TextStyle italicTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  fontStyle: FontStyle.italic,
  color: Colors.grey.shade700,
);

final TextStyle coupleNameTextStyle = GoogleFonts.satisfy(
  fontSize: 40,
  fontWeight: FontWeight.bold,
  color: Colors.purple.shade900,
);

// Reusable BoxDecoration
final BoxDecoration cardDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  color: Colors.white,
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 2,
    ),
  ],
);

final BoxDecoration gradientDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.purple.shade700, Colors.purple.shade300, Colors.white],
    stops: const [0.0, 0.3, 0.5],
  ),
);

final BoxDecoration circleImageDecoration = BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(color: Colors.purple.shade200, width: 5),
);
