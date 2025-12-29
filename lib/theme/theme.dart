import 'package:flutter/material.dart';

  ThemeData lightMode =  ThemeData(
      primarySwatch: Colors.orange,
      fontFamily: 'Trebuchet',
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigoAccent[700],
        unselectedItemColor: Colors.grey[600],
      ),
    );

  ThemeData darkMode = ThemeData(
      primarySwatch: Colors.orange,
      fontFamily: 'Trebuchet',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black, // True black for OLED
      cardTheme: CardThemeData(
        color: Colors.grey[900], // Very dark grey for cards
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.indigoAccent[700],
        unselectedItemColor: Colors.grey[400],
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
      ),
    );
  