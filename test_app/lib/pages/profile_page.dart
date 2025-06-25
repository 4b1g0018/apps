// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class ProfilePage extends StatefulWidget {
  final String account; // 接收從主選單傳來的帳號

  const ProfilePage({super.key, required this.account});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  // 我們用一個 User 物件來儲存目前的使用者資料
  User? _currentUser;
  
  // 為每個欄位建立一個 TextEditingController
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 從資料庫載入使用者資料並填充到輸入框中
  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    if (user != null) {
      setState(() {
        _currentUser = user;
        _heightController.text = user.height;
        _weightController.text = user.weight;
        _ageController.text = user.age;
        _fatController.text = user.fat ?? '';
        _bmiController.text = user.bmi;
      });
    }
  }

  // 更新 BMI 的函式
  void _updateBMI() {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);
    if (h != null && w != null && h > 0) {
      final bmi = w / ((h / 100) * (h / 100));
      _bmiController.text = bmi.toStringAsFixed(2);
    } else {
      _bmiController.text = '';
    }
  }

  // 儲存變更
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      // 使用 copyWith 來建立一個新的 User 物件，包含更新後的值
      final updatedUser = _currentUser!.copyWith(
        height: _heightController.text,
        weight: _weightController.text,
        age: _ageController.text,
        fat: _fatController.text,
        bmi: _bmiController.text,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('個人資料已更新！')),
      );
      Navigator.of(context).pop(); // 更新成功後返回上一頁
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料修改'),
        centerTitle: true,
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildTextField(controller: _heightController, label: '身高 (cm)', onChanged: (_) => _updateBMI()),
                  _buildTextField(controller: _weightController, label: '體重 (kg)', onChanged: (_) => _updateBMI()),
                  _buildTextField(controller: _ageController, label: '年齡'),
                  _buildTextField(controller: _fatController, label: '體脂率 (%)', isOptional: true),
                  TextFormField(
                    controller: _bmiController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'BMI (自動計算)'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('儲存變更'),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 將重複的 TextFormField 抽出來變成一個方法
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isOptional = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return '此欄位不得為空';
          }
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }
}
