// 使用者登入與註冊頁面。

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../main.dart';
import './fitness_level_page.dart'; // 【確認】導入新頁面

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _fat = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController();
  final List<bool> _genderSelection = [true, false];
  bool isLogin = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false; //仔入中狀態

  @override
  void dispose() {
    // 釋放所有控制器，是個好習慣
    _emailController.dispose();
    _passwordController.dispose();
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    _fat.dispose();
    _bmiController.dispose();
    _bmrController.dispose();
    super.dispose();
  }

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

  void _updateBMR() {
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    final a = int.tryParse(_age.text);
    final isMale = _genderSelection[0];

    if (h != null && w != null && a != null && h > 0 && w > 0 && a > 0) {
      double bmr = 0;
      if (isMale) {
        bmr = (10 * w) + (6.25 * h) - (5 * a) + 5;
      } else {
        bmr = (10 * w) + (6.25 * h) - (5 * a) - 161;
      }
      _bmrController.text = bmr.toStringAsFixed(2);
    } else {
      _bmrController.text = '';
    }
  }

  // 【修正】這是完整且正確的 _handleSubmit 方法
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    setState(() => _isLoading = true); //仔入畫面

    try {
    if (isLogin) {
      await AuthService.instance.signIn(email, password);
      if (!mounted) return;
        
        // 登入成功，導向主頁
        // (這裡未來可以優化：檢查雲端是否有使用者資料，決定去哪一頁)
        // 目前先直接進主頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainAppShell(account: email)),
        );

      } else {
        // --- Firebase 註冊 ---
        
        // 1. 先做基本的生理數值驗證
        final h = double.tryParse(_height.text);
        final w = double.tryParse(_weight.text);
        final a = int.tryParse(_age.text);
        if (h == null || w == null || a == null) {
          throw Exception("請填寫完整的生理數據");
        }

        // 2. 呼叫 Firebase 建立帳號
        await AuthService.instance.signUp(email, password);

        // 3. (選做) 將生理數據存入本地資料庫作為暫存，
        // 或者未來我們要將這些數據存到 Firebase Firestore (雲端資料庫)
        // 這裡先維持存本地，讓 App 能跑
        final gender = _genderSelection[0] ? 'male' : 'female';
        String bmi = (w / ((h / 100) * (h / 100))).toStringAsFixed(2);
        double bmrValue = (gender == 'male') 
            ? (10 * w) + (6.25 * h) - (5 * a) + 5
            : (10 * w) + (6.25 * h) - (5 * a) - 161;
        String bmr = bmrValue.toStringAsFixed(2);

        await DatabaseHelper.instance.insertUser({
          'account': email, // 用 Email 當作 account
          'password': 'firebase_user', // 本地密碼隨意，因為驗證在雲端
          'height': _height.text,
          'weight': _weight.text,
          'age': _age.text,
          'bmi': bmi,
          'fat': _fat.text,
          'gender': gender,
          'bmr': bmr,
        });

        if (!mounted) return;

        // 註冊成功，導向強度選擇頁
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FitnessLevelPage(account: email)),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 處理 Firebase 回傳的具體錯誤
      String message = '發生錯誤';
      if (e.code == 'user-not-found') {
        message = '找不到此使用者，請先註冊';
      } else if (e.code == 'wrong-password') {
        message = '密碼錯誤';
      } else if (e.code == 'email-already-in-use') {
        message = '此 Email 已經被註冊過了';
      } else if (e.code == 'invalid-email') {
        message = 'Email 格式不正確';
      } else if (e.code == 'weak-password') {
        message = '密碼強度不足 (至少6位)';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false); // 隱藏轉圈圈
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
                  const Icon(Icons.fitness_center, size: 80, color: Color(0xFF0A84FF)),
                  const SizedBox(height: 20),
                  Text(isLogin ? '歡迎回來！' : '建立您的帳戶', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(isLogin ? '登入以繼續您的訓練' : '填寫資料以開始個人化體驗', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 40),
                  
                  // 【修改】輸入框提示改為 Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email', 
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email_outlined)
                    ),
                    keyboardType: TextInputType.emailAddress, // 跳出 Email 鍵盤
                    validator: (v) => v!.isEmpty ? '請輸入 Email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
                  ),
                  
                  if (!isLogin) ...[
                    const SizedBox(height: 24),
                    ToggleButtons(
                      isSelected: _genderSelection,
                      onPressed: (int index) {
                        setState(() {
                          for (int i = 0; i < _genderSelection.length; i++) {
                            _genderSelection[i] = i == index;
                          }
                          _updateBMR();
                        });
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      constraints: BoxConstraints.expand(width: (MediaQuery.of(context).size.width - 52) / 2, height: 40),
                      fillColor: _genderSelection[1] ? Colors.red.shade400 : Colors.blue.shade400,
                      selectedColor: Colors.white,
                      children: const [Text('男性'), Text('女性')],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '身高 (cm)'), validator: (v) => v!.isEmpty ? '請輸入身高' : null, onChanged: (_) { _updateBMI(); _updateBMR(); },),
                    const SizedBox(height: 16),
                    TextFormField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '體重 (kg)'), validator: (v) => v!.isEmpty ? '請輸入體重' : null, onChanged: (_) { _updateBMI(); _updateBMR(); },),
                    const SizedBox(height: 16),
                    TextFormField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '年齡'), validator: (v) => v!.isEmpty ? '請輸入年齡' : null, onChanged: (_) => _updateBMR(),),
                    const SizedBox(height: 16),
                    TextFormField(readOnly: true, controller: _bmiController, decoration: const InputDecoration(labelText: 'BMI (自動計算)')),
                    const SizedBox(height: 16),
                    TextFormField(readOnly: true, controller: _bmrController, decoration: const InputDecoration(labelText: 'BMR (自動計算)')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _fat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '體脂率 (%) (選填)')),
                  ],
                  const SizedBox(height: 30),
                  
                  // 【修改】按鈕顯示載入中狀態
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isLogin ? '登入' : '註冊'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? '還沒有帳號？' : '已經有帳號？', style: TextStyle(color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(isLogin ? ' 馬上註冊' : ' 前往登入', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A84FF))),
                      ),
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