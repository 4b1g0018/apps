

import 'package:flutter/material.dart';
// 引入檔案
import './services/database_helper.dart';
import './pages/login_page.dart';

//flutter環境建置
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化資料庫
  await DatabaseHelper.instance.initDB();
  runApp(const MyApp());
}

//開始
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健身教練 App',
      // 隱藏 Debug 標籤
      debugShowCheckedModeBanner: false, 
      // 設定首頁
      home: const LoginPage(),
    );
  }
}
