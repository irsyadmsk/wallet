import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core.dart';

ThemeData getDefaultTheme() {
  return ThemeData().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    appBarTheme: AppBarTheme(
      toolbarHeight: 80,
      centerTitle: false,
      elevation: 0.0,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 14,
        color: const Color.fromARGB(255, 255, 255, 255),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: scaffoldBackgroundColor,
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
      actionsIconTheme: const IconThemeData(color: Colors.black),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      unselectedItemColor: Colors.grey,
      selectedItemColor: Colors.blueGrey[900],
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    tabBarTheme: TabBarThemeData(
      unselectedLabelColor: Colors.grey,
      labelColor: Colors.blueGrey[900],
    ),
    iconTheme: IconThemeData(color: primaryColor),
    textTheme: TextTheme(
      titleSmall: GoogleFonts.roboto(color: textColor),
      titleMedium: GoogleFonts.roboto(color: textColor),
      titleLarge: GoogleFonts.roboto(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.roboto(color: textColor),
      bodySmall: GoogleFonts.roboto(color: textColor),
      bodyMedium: GoogleFonts.roboto(color: textColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(vertical: 0),
      hintStyle: TextStyle(
        color: Color(0xffd8d4d4),
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
      ),
      hoverColor: Colors.transparent,
      errorMaxLines: 1,
      // border: OutlineInputBorder(
      //   borderRadius: BorderRadius.circular(8),
      //   borderSide: BorderSide(color: Colors.grey[300]!),
      // ),
      // enabledBorder: OutlineInputBorder(
      //   borderSide: BorderSide(color: Color(0xffd8d4d4), width: 1.4),
      // ),
      // errorBorder: OutlineInputBorder(
      //   borderSide: BorderSide(color: primaryColor, width: 1.4),
      // ),
      // focusedErrorBorder: OutlineInputBorder(
      //   borderSide: BorderSide(color: primaryColor, width: 1.4),
      // ),
      // disabledBorder: OutlineInputBorder(
      //   borderSide: BorderSide(color: Colors.grey[300]!),
      // ),
      // focusedBorder: OutlineInputBorder(
      //   borderSide: BorderSide(color: primaryColor, width: 1.4),
      // ),
      filled: true,
      fillColor: scaffoldBackgroundColor,
    ),
    cardTheme: CardThemeData(
      elevation: 0.6,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(width: 0.4, color: Colors.grey[300]!),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        backgroundColor: Colors.blueGrey,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      dataTextStyle: TextStyle(color: textColor),
      headingRowColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey[200]!;
        }
        return Colors.grey[300]!;
      }),
      headingTextStyle: const TextStyle(),
      dataRowColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey[200]!;
        }
        return Colors.white;
      }),
      dataRowMinHeight: 48,
    ),
  );
}
