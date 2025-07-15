// lib/pages/login_page.dart


import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../main.dart';

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
  final TextEditingController _bmrController = TextEditingController();
  final List<bool> _genderSelection = [true, false]; 
  bool isLogin = true;
  bool _isPasswordVisible = false;
  
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
          MaterialPageRoute(builder: (_) => MainAppShell(account: acc)),
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

       final a = int.tryParse(_age.text);
      final gender = _genderSelection[0] ? 'male' : 'female';
      String bmr = '';
      if (h != null && w != null && a != null && h > 0 && w > 0 && a > 0) {
        double bmrValue = 0;
        if (gender == 'male') {
          bmrValue = (10 * w) + (6.25 * h) - (5 * a) + 5;
        } else {
          bmrValue = (10 * w) + (6.25 * h) - (5 * a) - 161;
        }
        bmr = bmrValue.toStringAsFixed(2);
      }
      if (bmi == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BMI 計算失敗，請輸入正確的身高與體重')),
        );
        return;
      }

        if (bmr == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BMR 計算失敗，請輸入正確的身高、體重與年齡')),
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
        'gender': gender,
        'bmr': bmr,
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
                    // `obscureText` 這個屬性用來決定是否要將文字顯示為星號或圓點
                    // 它的值，現在由我們新增的 `_isPasswordVisible` 狀態來控制。
                    // `!` 是「非」的意思，所以 `!_isPasswordVisible` 代表：當密碼「不可見」時，這個值為 true (隱藏文字)。
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      // `suffixIcon` 可以在輸入框的「最右邊」加上一個圖示按鈕
                      suffixIcon: IconButton(
                        // 我們根據 `_isPasswordVisible` 的狀態，來決定要顯示「眼睛打開」還是「眼睛關閉」的圖示
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined // 如果可見，顯示「關眼」圖示
                              : Icons.visibility_outlined,    // 如果不可見，顯示「開眼」圖示
                        ),
                        // 當使用者點擊這個圖示按鈕時
                        onPressed: () {
                          // 我們呼叫 setState，並將 `_isPasswordVisible` 的狀態反轉
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
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
                          // 性別變動後，也要重新計算 BMR
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
                    TextFormField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '身高 (cm)'),
                      validator: (v) => v!.isEmpty ? '請輸入身高' : null,
                      onChanged: (_) {
                        _updateBMI();
                        _updateBMR();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '體重 (kg)'),
                      validator: (v) => v!.isEmpty ? '請輸入體重' : null,
                      onChanged: (_) {
                        _updateBMI();
                        _updateBMR();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '年齡'),
                      validator: (v) => v!.isEmpty ? '請輸入年齡' : null,
                      onChanged: (_) => _updateBMR(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _bmiController,
                      decoration: const InputDecoration(labelText: 'BMI (自動計算)'),
                    ),
                     const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: _bmrController,
                      decoration: const InputDecoration(labelText: 'BMR (自動計算)'),
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
