// 使用者個人資料的檢視與修改頁面。

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class ProfilePage extends StatefulWidget {
  final String account;
  const ProfilePage({super.key, required this.account});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController(); 
  final TextEditingController _goalWeightController = TextEditingController();
  
  @override
  void initState() { super.initState(); _loadUserData(); }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _heightController.text = user.height;
        _weightController.text = user.weight;
        _ageController.text = user.age;
        _fatController.text = user.fat ?? '';
        _bmiController.text = user.bmi;
        _bmrController.text = user.bmr ?? '';
        _goalWeightController.text = user.goalWeight ?? '';
      });
    }
  }

  void _calculateMetrics() {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);
    final a = int.tryParse(_ageController.text);

    if (h != null && w != null && h > 0) {
      final bmi = w / ((h / 100) * (h / 100));
      _bmiController.text = bmi.toStringAsFixed(2);

        //BMR 計算邏輯
      if (a != null && a > 0 && _currentUser?.gender != null) {
        double bmr = 0;
        if (_currentUser!.gender == 'male') {
          bmr = (10 * w) + (6.25 * h) - (5 * a) + 5;
        } else {
          bmr = (10 * w) + (6.25 * h) - (5 * a) - 161;
        }
        _bmrController.text = bmr.toStringAsFixed(2);
      } else {
        _bmrController.text = '';
      }

    } else {
      _bmiController.text = '';
      _bmrController.text = ''; // 【新增】如果身高體重無效，也清空 BMR
    }
    // 因為我們是直接操作 Controller 的 text，如果希望畫面即時反應可以不用 setState
    // 但如果後續有其他依賴狀態的 UI，加上 setState 會更保險
    setState(() {});
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        height: _heightController.text,
        weight: _weightController.text,
        age: _ageController.text,
        fat: _fatController.text,
        bmi: _bmiController.text,
        bmr: _bmrController.text,
        goalWeight: _goalWeightController.text,
      );
      await DatabaseHelper.instance.updateUser(updatedUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('個人資料已更新！')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料修改'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildLabeledTextField(
                    label: '身高 (cm)',
                    controller: _heightController,
                    onChanged: (_) => _calculateMetrics(), 
                    validator: (v) => v!.isEmpty ? '此欄位不得為空' : null,
                  ),
                  const SizedBox(height: 24), // 加大欄位之間的垂直間距
                  _buildLabeledTextField(
                    label: '體重 (kg)',
                    controller: _weightController,
                    onChanged: (_) => _calculateMetrics(), 
                    validator: (v) => v!.isEmpty ? '此欄位不得為空' : null,
                  ),
                  const SizedBox(height: 24),
                   _buildLabeledTextField(
                    label: '目標體重 (kg)',
                    controller: _goalWeightController,
                  ),
                  const SizedBox(height: 24),
                  _buildLabeledTextField(
                    label: '年齡',
                    controller: _ageController,
                    onChanged: (_) => _calculateMetrics(),
                    validator: (v) => v!.isEmpty ? '此欄位不得為空' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildLabeledTextField(
                    label: '體脂率 (%) (選填)',
                    controller: _fatController,
                    isOptional: true,
                  ),
                  const SizedBox(height: 24),
                  // 對於唯讀的欄位，我們也套用一樣的樣式
                  _buildLabeledTextField(
                    label: 'BMI (自動計算)',
                    controller: _bmiController,
                    readOnly: true,
                  ),

                const SizedBox(height: 24),
                _buildLabeledTextField(
                 label: 'BMR (基礎代謝率) (自動計算)',
                  controller: _bmrController,
                  readOnly: true,
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('儲存變更'),
                  ),
                ],
              ),
            ),
    );
  }

  // --- 【全新 Helper 方法】 ---
  // 這個方法會建立一個包含「標題」和「輸入框」的組合元件
  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool isOptional = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      // 讓裡面的元件都向左對齊
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 這是永遠顯示在上面的「常駐標題」
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8), // 標題和輸入框之間的間距
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          // 我們不再需要 labelText 或 hintText，因為標題已經在外面了
          decoration: const InputDecoration(),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
