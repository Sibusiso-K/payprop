import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand primaries
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1341B0);
  static const Color primaryLight = Color(0xFFEBF0FF);

  // Accent
  static const Color accent = Color(0xFF0EA5E9);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Neutrals
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // Role-specific accents
  static const Color tenantAccent = Color(0xFF7C3AED);   // purple
  static const Color agentAccent = Color(0xFF1A56DB);    // blue (primary)
  static const Color ownerAccent = Color(0xFF059669);    // green
}
