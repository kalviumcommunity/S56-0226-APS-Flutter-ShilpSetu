import 'package:flutter/material.dart';

/// Final Earthy Artisan Design System - Refined Color Palette
/// Warm, elegant, premium aesthetic with muted tones
class AppColors {
  // Background (Main App Background)
  static const Color softWarmBeige = Color(0xFFF6F1E8);
  static const Color background = softWarmBeige;
  
  // Card / Surface Colors
  static const Color primarySurface = Color(0xFFFFFFFF); // White cards
  static const Color secondarySurface = Color(0xFFEFE7DA); // Soft warm cream
  static const Color surface = primarySurface; // Default surface
  static const Color card = primarySurface; // Card alias
  
  // Text Colors
  static const Color deepCharcoalBrown = Color(0xFF2E2A26);
  static const Color textPrimary = deepCharcoalBrown;
  
  static const Color mutedWarmGrey = Color(0xFF8A817C);
  static const Color textSecondary = mutedWarmGrey;
  
  // Primary Accent (Brand Color) - Use ONLY for interactive elements
  static const Color mutedForestGreen = Color(0xFF2F5D50);
  static const Color primaryAccent = mutedForestGreen;
  static const Color forestJade = mutedForestGreen; // Alias for compatibility
  
  // Soft Accent (Tags, Chips, Subtle Highlights)
  static const Color lightSageTint = Color(0xFFDCE5DD);
  static const Color softAccent = lightSageTint;
  static const Color mintBloom = lightSageTint; // Alias for compatibility
  
  // Status Colors (Muted)
  static const Color mutedTerracotta = Color(0xFFC96C5B);
  static const Color error = mutedTerracotta;
  
  static const Color softMutedGreen = Color(0xFF4F7A63);
  static const Color success = softMutedGreen;
  
  static const Color mutedGold = Color(0xFFC8A24C);
  static const Color warning = mutedGold;
  static const Color rating = mutedGold; // For star ratings
  
  // Utility Colors
  static const Color divider = Color(0xFFD9D0C7);
  static const Color inputBorder = Color(0xFFD9D0C7);
  
  // Dark Accent (for icons, strong emphasis)
  static const Color darkAccent = deepCharcoalBrown;
  static const Color deepEvergreen = mutedForestGreen; // Alias for compatibility
  
  // Legacy aliases for backward compatibility
  @Deprecated('Use primaryAccent or mutedForestGreen instead')
  static const Color primary = mutedForestGreen;
  
  @Deprecated('Use softAccent or lightSageTint instead')
  static const Color secondary = lightSageTint;
  
  @Deprecated('Use softAccent instead')
  static const Color secondaryAccent = lightSageTint;
  
  @Deprecated('Use textPrimary instead')
  static const Color text = deepCharcoalBrown;
  
  @Deprecated('Use textSecondary instead')
  static const Color muted = mutedWarmGrey;
  
  @Deprecated('Use background instead')
  static const Color softPistachio = softWarmBeige;
  
  @Deprecated('Use surface instead')
  static const Color warmNeutralBeige = primarySurface;
  
  @Deprecated('Use textPrimary instead')
  static const Color darkSlate = deepCharcoalBrown;
  
  @Deprecated('Use textSecondary instead')
  static const Color softGray = mutedWarmGrey;
}
