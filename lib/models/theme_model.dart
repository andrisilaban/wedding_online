// models/theme_model.dart
import 'package:flutter/material.dart';

class WeddingTheme {
  final String id;
  final String name;
  final String description;
  final List<Color> gradientColors;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBackground;
  final String fontFamily;
  final String backgroundAsset;
  final List<String> decorativeIcons;

  const WeddingTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBackground,
    required this.fontFamily,
    required this.backgroundAsset,
    required this.decorativeIcons,
  });
}
