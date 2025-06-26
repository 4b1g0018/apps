// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import './main_menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _account = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _fat = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  bool isLogin = true;

  void _toggleMode() => setState(() => isLogin = !isLogin);

  void _updateBMI() {
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    if (h != null && w != null && h > 0) {
      final bmi = w / ((h / 100) * (h / 100));
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '';
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final acc = _account.text.trim();
    final pwd = _password.text.trim();

    if (isLogin) {
      final valid = await DatabaseHelper.instance.validateUser(acc, pwd);
      if (!mounted) return;
      if (valid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuPage(account: acc)),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('帳號或密碼錯誤')));
      }
    } else {
      final h = double.tryParse(_height.text);
      final w = double.tryParse(_weight.text);
      final bmi = (h != null && w != null && h > 0)
          ? (w / ((h / 100) * (h / 100))).toStringAsFixed(2)
          : '';
      if (bmi == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BMI 計算失敗，請輸入正確的身高與體重')),
        );
        return;
      }
      await DatabaseHelper.instance.insertUser({
        'account': acc,
        'password': pwd,
        'height': _height.text,
        'weight': _weight.text,
        'age': _age.text,
        'bmi': bmi,
        'fat': _fat.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('註冊成功，請登入')));
      setState(() => isLogin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.fitness_center, size: 80, color: Color(0xFF007AFF)),
                  const SizedBox(height: 20),
                  Text(isLogin ? '歡迎回來！' : '建立您的帳戶', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(isLogin ? '登入以繼續您的訓練' : '填寫資料以開始個人化體驗', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _account,
                    decoration: const InputDecoration(labelText: '帳號'),
                    validator: (v) => v!.isEmpty ? '請輸入帳號' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: '密碼'),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
                  ),
                  
                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '身高 (cm)'),
                      validator: (v) => v!.isEmpty ? '請輸入身高' : null,
                      onChanged: (_) => _updateBMI(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '體重 (kg)'),
                      validator: (v) => v!.isEmpty ? '請輸入體重' : null,
                      onChanged: (_) => _updateBMI(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '年齡'),
                      validator: (v) => v!.isEmpty ? '請輸入年齡' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _bmiController,
                      decoration: const InputDecoration(labelText: 'BMI (自動計算)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fat,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '體脂率 (%) (選填)'),
                    ),
                  ],
                  const SizedBox(height: 30),
                  
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _handleSubmit, child: Text(isLogin ? '登入' : '註冊'))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? '還沒有帳號？' : '已經有帳號？', style: TextStyle(color: Colors.grey.shade600)),
                      GestureDetector(onTap: _toggleMode, child: Text(isLogin ? ' 馬上註冊' : ' 前往登入', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF)))),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
