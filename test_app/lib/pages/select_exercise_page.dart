// lib/pages/select_exercise_page.dart

import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/mock_data_service.dart';
import './exercise_setup_page.dart';

class SelectExercisePage extends StatefulWidget {
  final BodyPart bodyPart;
  const SelectExercisePage({super.key, required this.bodyPart});

  @override
  State<SelectExercisePage> createState() => _SelectExercisePageState();
}

class _SelectExercisePageState extends State<SelectExercisePage> {
  late final List<Exercise> _predefinedExercises;

  @override
  void initState() {
    super.initState();
    _predefinedExercises = MockDataService.getExercisesForBodyPart(widget.bodyPart);
  }

  void _goToSetupPage(Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSetupPage(
          exercise: exercise,
          bodyPart: widget.bodyPart,
        ),
      ),
    );
  }

  Future<void> _showAddCustomExerciseDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增自訂動作'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '動作名稱'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入動作名稱' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final customExercise = Exercise(name: nameController.text.trim());
                  Navigator.of(context).pop();
                  _goToSetupPage(customExercise);
                }
              },
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bodyPartName = widget.bodyPart.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text('選擇 $bodyPartName 動作'),
      ),
      body: ListView.builder(
        itemCount: _predefinedExercises.length,
        itemBuilder: (context, index) {
          final exercise = _predefinedExercises[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              // 【修正】現在 description 是可選的，我們可以直接使用它
              subtitle: Text(exercise.description ?? ''), // 如果 description 是 null，就顯示空字串
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _goToSetupPage(exercise),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomExerciseDialog,
        tooltip: '新增自訂動作',
        child: const Icon(Icons.add),
      ),
    );
  }
}