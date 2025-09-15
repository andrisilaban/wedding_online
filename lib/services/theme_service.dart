// services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:wedding_online/models/theme_model.dart';
import 'package:wedding_online/services/storage_service.dart';

class ThemeService {
  final StorageService _storageService = StorageService();

  // Available Themes
  static final List<WeddingTheme> availableThemes = [
    // 1. Royal Purple (Original)
    WeddingTheme(
      id: 'royal_purple',
      name: 'Royal Purple',
      description: 'Elegan dan mewah dengan nuansa kerajaan',
      gradientColors: [
        Color(0xFF4A148C),
        Color(0xFF7B1FA2),
        Color(0xFF9C27B0),
        Color(0xFFBA68C8),
      ],
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFF9C27B0),
      accentColor: Color(0xFFBA68C8),
      textPrimary: Color(0xFF1A1A1A),
      textSecondary: Color(0xFF757575),
      cardBackground: Colors.white,
      fontFamily: 'Cormorant',
      backgroundAsset: 'assets/patterns/royal_pattern.png',
      decorativeIcons: ['👑', '💜', '✨', '💎'],
    ),

    // 2. Romantic Rose Gold
    WeddingTheme(
      id: 'romantic_rose',
      name: 'Romantic Rose',
      description: 'Romantis dan lembut dengan sentuhan rose gold',
      gradientColors: [
        Color(0xFFAD1457),
        Color(0xFFE91E63),
        Color(0xFFF06292),
        Color(0xFFF8BBD9),
      ],
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFFF06292),
      accentColor: Color(0xFFFFAB91),
      textPrimary: Color(0xFF2C2C2C),
      textSecondary: Color(0xFF8D6E63),
      cardBackground: Color(0xFFFFF8F5),
      fontFamily: 'Dancing Script',
      backgroundAsset: 'assets/patterns/rose_pattern.png',
      decorativeIcons: ['🌹', '💕', '🌸', '💖'],
    ),

    // 3. Ocean Blue
    WeddingTheme(
      id: 'ocean_blue',
      name: 'Ocean Blue',
      description: 'Sejuk dan tenang seperti laut biru',
      gradientColors: [
        Color(0xFF0D47A1),
        Color(0xFF1976D2),
        Color(0xFF42A5F5),
        Color(0xFF81D4FA),
      ],
      primaryColor: Color(0xFF1976D2),
      secondaryColor: Color(0xFF42A5F5),
      accentColor: Color(0xFF81D4FA),
      textPrimary: Color(0xFF263238),
      textSecondary: Color(0xFF546E7A),
      cardBackground: Color(0xFFF3F8FF),
      fontFamily: 'Playfair Display',
      backgroundAsset: 'assets/patterns/ocean_pattern.png',
      decorativeIcons: ['🌊', '🐚', '⚓', '🦋'],
    ),

    // 4. Sunset Orange
    WeddingTheme(
      id: 'sunset_orange',
      name: 'Sunset Orange',
      description: 'Hangat dan ceria seperti matahari terbenam',
      gradientColors: [
        Color(0xFFBF360C),
        Color(0xFFFF5722),
        Color(0xFFFF8A65),
        Color(0xFFFFCC02),
      ],
      primaryColor: Color(0xFFFF5722),
      secondaryColor: Color(0xFFFF8A65),
      accentColor: Color(0xFFFFCC02),
      textPrimary: Color(0xFF3E2723),
      textSecondary: Color(0xFF6D4C41),
      cardBackground: Color(0xFFFFF8E1),
      fontFamily: 'Pacifico',
      backgroundAsset: 'assets/patterns/sunset_pattern.png',
      decorativeIcons: ['🌅', '🧡', '🌻', '🔥'],
    ),

    // 5. Forest Green
    WeddingTheme(
      id: 'forest_green',
      name: 'Forest Green',
      description: 'Natural dan segar seperti hutan hijau',
      gradientColors: [
        Color(0xFF1B5E20),
        Color(0xFF388E3C),
        Color(0xFF66BB6A),
        Color(0xFFA5D6A7),
      ],
      primaryColor: Color(0xFF388E3C),
      secondaryColor: Color(0xFF66BB6A),
      accentColor: Color(0xFFA5D6A7),
      textPrimary: Color(0xFF1B4332),
      textSecondary: Color(0xFF2D5016),
      cardBackground: Color(0xFFF1F8E9),
      fontFamily: 'Merriweather',
      backgroundAsset: 'assets/patterns/forest_pattern.png',
      decorativeIcons: ['🌿', '🍃', '🌳', '🦋'],
    ),
  ];

  // Get current theme
  Future<WeddingTheme> getCurrentTheme() async {
    final themeId = await _storageService.getSelectedTheme();
    return availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => availableThemes.first, // Default to Royal Purple
    );
  }

  // Save selected theme
  Future<void> saveTheme(String themeId) async {
    await _storageService.saveSelectedTheme(themeId);
  }

  // Get theme by ID
  WeddingTheme getThemeById(String themeId) {
    return availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => availableThemes.first,
    );
  }
}
