import 'package:flutter/material.dart';

/// App Color Configuration
/// Centralized color scheme for the entire application
class AppColors {
  // Primary Color Scheme (Main Brand Colors)
  // Blue Palette
  static const Color primaryBlue = Color(0xFF006896); // Deep ocean blue
  static const Color secondaryBlue = Color(0xFF0197b2); // Teal blue
  static const Color tertiaryBlue = Color(0xFF00adc9); // Bright cyan

  // Accent Colors
  static const Color accentGreen = Color(0xFF2e8a57); // Forest green
  static const Color accentYellow = Color(0xFFf1dd6b); // Soft yellow
  static const Color accentOrange = Color(0xFFf46640); // Coral orange

  // Text Colors
  static const Color textDark = Color(0xFF333333); // Dark gray
  static const Color textLight = Color(0xFFffffff); // White

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryBlue], // Blue to teal
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryBlue, tertiaryBlue], // Teal to cyan
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, tertiaryBlue], // Green to cyan
  );

  // Additional Colors (Used in specific sections)
  // Purple Gradient
  static const Color purpleGradientStart = Color(0xFF667eea);
  static const Color purpleGradientEnd = Color(0xFF764ba2);
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleGradientStart, purpleGradientEnd],
  );

  // Teal Colors (Used in gallery)
  static const Color tealDark = Color(0xFF008080);
  static const Color tealLight = Color(0xFF20B2AA);

  // Pink Accent (Used for approach icons)
  static const Color pinkAccent = Color(0xFFf093fb);

  // Neutral Colors
  // Background colors
  static const Color backgroundLight1 = Color(0xFFf8f9fa);
  static const Color backgroundLight2 = Color(0xFFf7f9ff);
  static const Color backgroundLight3 = Color(0xFFf9f9f9);

  // Gray shades
  static const Color gray1 = Color(0xFF6c757d);
  static const Color gray2 = Color(0xFF4a5568);
  static const Color gray3 = Color(0xFF4b5563);

  // Dark shades
  static const Color dark1 = Color(0xFF1a1a1a);
  static const Color dark2 = Color(0xFF111827);
  static const Color dark3 = Color(0xFF2c3e50);

  // Status Colors
  static const Color success = accentGreen;
  static const Color warning = accentYellow;
  static const Color error = accentOrange;
  static const Color info = tertiaryBlue;

  // UI Component Colors
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE5E7EB);
  
  // Opacity variations
  static Color primaryBlueLight = primaryBlue.withOpacity(0.1);
  static Color primaryBlueMedium = primaryBlue.withOpacity(0.3);
  static Color secondaryBlueLight = secondaryBlue.withOpacity(0.1);
  static Color accentGreenLight = accentGreen.withOpacity(0.1);
  static Color accentOrangeLight = accentOrange.withOpacity(0.1);

  // Helper method to get gradient colors as list
  static List<Color> getPrimaryGradientColors() => [primaryBlue, secondaryBlue];
  static List<Color> getSecondaryGradientColors() => [secondaryBlue, tertiaryBlue];
  static List<Color> getAccentGradientColors() => [accentGreen, tertiaryBlue];
  static List<Color> getPurpleGradientColors() => [purpleGradientStart, purpleGradientEnd];

  // Card colors for different categories
  static List<Color> categoryColors = [
    primaryBlue,
    secondaryBlue,
    tertiaryBlue,
    accentGreen,
    accentYellow,
    accentOrange,
  ];
}
