// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import './main_menu_page.dart';

//  登入與註冊頁面
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

  bool isLogin = true; // true = 登入, false = 正在註冊

  // 切換登入與註冊模式
  void _toggleMode() => setState(() => isLogin = !isLogin);

  // 提交登入或註冊資料
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
          MaterialPageRoute(builder: (_) => const MainMenuPage()),
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

  // 計算 BMI
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? '登入' : '註冊')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _account,
                decoration: const InputDecoration(labelText: '帳號'),
                validator: (v) => v!.isEmpty ? '請輸入帳號' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
              ),
              if (!isLogin) ...[
                TextFormField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '身高 (cm)'),
                  validator: (v) => v!.isEmpty ? '請輸入身高' : null,
                  onChanged: (_) => _updateBMI(),
                ),
                TextFormField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '體重 (kg)'),
                  validator: (v) => v!.isEmpty ? '請輸入體重' : null,
                  onChanged: (_) => _updateBMI(),
                ),
                TextFormField(
                  readOnly: true,
                  controller: _bmiController,
                  decoration: const InputDecoration(labelText: 'BMI(自動計算)'),
                ),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '年齡'),
                  validator: (v) => v!.isEmpty ? '請輸入年齡' : null,
                ),
                TextFormField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '體脂率（選填）'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSubmit,
                child: Text(isLogin ? '登入' : '註冊'),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text(isLogin ? '還沒有帳號？註冊' : '已有帳號？登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
