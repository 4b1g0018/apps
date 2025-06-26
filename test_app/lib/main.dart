// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import './services/database_helper.dart';
import './pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await DatabaseHelper.instance.initDB();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // 我們選用一個更沉穩、帶有黑色調的深藍色
    const Color primaryColor = Color(0xFF2563EB);

    return MaterialApp(
      title: '智慧健身 App',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PingFang TC',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E), 

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor, 
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1C1E),
          primary: primaryColor,
        ),

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF2C2C2E), 
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primaryColor, 
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'PingFang TC',
            )
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          floatingLabelStyle: const TextStyle(
            color: primaryColor,
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}
