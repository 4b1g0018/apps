// 建議課程頁面

import 'package:flutter/material.dart';

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('建議課程'),
      ),
      body: const Center(
        child: Text(
          '建議課程頁面 (待開發)',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}