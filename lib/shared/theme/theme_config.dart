import 'package:flutter/material.dart';

/// Legacy mutable color globals, kept only because a handful of reusable
/// form widgets (`lib/shared/widget/form/**`) read them directly instead of
/// `context.colors`. [ThemeController] keeps these in sync with the real
/// (dark-mode-aware) [AppColors] whenever the seed color or theme mode
/// changes — see `syncLegacyGlobals` in `theme_controller.dart`.
Color primaryColor = const Color(0xFF4F46E5);
Color secondaryColor = const Color(0xFF6366F1);
Color disabledColor = const Color(0xFFE2E8F0);
Color textColor = const Color(0xFF0F172A);
Color secondaryTextColor = const Color(0xFF64748B);
Color scaffoldBackgroundColor = const Color(0xFFF8FAFC);

Color successColor = const Color(0xFF10B981);
Color dangerColor = const Color(0xFFEF4444);
Color warningColor = const Color(0xFFF59E0B);
Color infoColor = const Color(0xFF0EA5E9);

Color inputColor = const Color(0xFF1E293B);
double inputHeight = 52;
double cardBorderRadius = 16.0;
