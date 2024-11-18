import 'package:flutter/material.dart';

ThemeData appTheme(){
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent[700]!,
      brightness: Brightness.dark
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color.fromARGB(255, 14, 14, 14),
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold)
    ),
    snackBarTheme: const SnackBarThemeData(
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
    )
  );
}