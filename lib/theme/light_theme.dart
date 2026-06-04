import 'package:flutter/material.dart';
import 'package:ride_sharing_user_app/theme/custom_theme_colors.dart';

ThemeData lightTheme = ThemeData(
    fontFamily: 'SFProText',
    primaryColor: const Color(0xFFFF6B09),
    disabledColor: const Color(0xFFBABFC4),
    primaryColorDark: const Color(0xffcc580d),
    brightness: Brightness.light,
    hintColor: const Color(0xFF1F1F1F),
    cardColor: Colors.white,
    extensions: <ThemeExtension<CustomThemeColors>>[CustomThemeColors.light()],
    colorScheme: const ColorScheme.light(
        primary: Color(0xFFF8C09B),
        surface: Color(0xFFF3F3F3),
        error: Color(0xFFFF6767),
        secondary: Color(0xFFAA4602),
        tertiary: Color(0xFFC19272),
        tertiaryContainer: Color(0xFFC98B3E),
        secondaryContainer: Color(0xFFEE6464),
        onTertiary: Color(0xFFD9D9D9),
        onSecondary: Color(0xFFF1893F),
        onSecondaryContainer: Color(0xFFA8C5C1),
        onTertiaryContainer: Color(0xFF425956),
        outline: Color(0xFFFABA8F),
        onPrimaryContainer: Color(0xFFDEFFFB),
        primaryContainer: Color(0xFFFFA800),
        onErrorContainer: Color(0xFFFFE6AD),
        onPrimary: Color(0xFFFF6B09),
        surfaceTint: Color(0xFAD36720),
        errorContainer: Color(0xFFF6F6F6),
        shadow: Color(0xFFCEFCF7),
        surfaceContainer: Color(0xFF0094FF),
        secondaryFixedDim: Color(0xFF808080)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFAFD8C41))),
    textTheme: const TextTheme(
      displayLarge:
          TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF202020)),
      displayMedium:
          TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF393939)),
      displaySmall:
          TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF282828)),
      bodyLarge:
          TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF272727)),
      bodyMedium:
          TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF111111)),
      bodySmall:
          TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF111111)),
    ));
