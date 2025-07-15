// lib/pages/dashboard_home_page.dart

import 'package:flutter/material.dart';

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁'),
      ),
      body: const Center(
        child: Text(
          '儀表板頁面 (待開發)',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}