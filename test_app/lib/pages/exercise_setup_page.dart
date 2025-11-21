// lib/pages/exercise_setup_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/plan_item_model.dart'; // 【新增】導入 PlanItem 模型
import './training_session_page.dart';

class ExerciseSetupPage extends StatefulWidget {
  final Exercise exercise;
  final BodyPart bodyPart;

  const ExerciseSetupPage({
    super.key,
    required this.exercise,
    required this.bodyPart,
  });
  @override
  State<ExerciseSetupPage> createState() => _ExerciseSetupPageState();
}

class _ExerciseSetupPageState extends State<ExerciseSetupPage> {
  int _sets = 3;
  int _restMinutes = 1;
  int _restSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          /*
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white54, size: 50),
                  SizedBox(height: 8),
                  Text('教學影片 (待加入)', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          */

          Text('訓練參數', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('訓練組數：', style: TextStyle(fontSize: 16)),
              const Spacer(),
              Text('$_sets 組', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          _buildPicker(
            itemCount: 20,
            onSelectedItemChanged: (index) {
              setState(() {
                _sets = index + 1;
              });
            },
            initialItem: _sets - 1,
          ),
          const SizedBox(height: 16),
          const Text('休息時間：', style: TextStyle(fontSize: 16)),
          Row(
            children: [
              Expanded(
                child: _buildPicker(
                  itemCount: 10,
                  onSelectedItemChanged: (index) => setState(() => _restMinutes = index),
                  initialItem: _restMinutes,
                  suffix: '分',
                ),
              ),
              Expanded(
                child: _buildPicker(
                  itemCount: 6,
                  onSelectedItemChanged: (index) => setState(() => _restSeconds = index * 10),
                  initialItem: _restSeconds ~/ 10,
                  isSeconds: true,
                  suffix: '秒',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_restMinutes == 0 && _restSeconds == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('休息時間不能為 0 秒，請重新設定！'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // 【修正】建立一個臨時的 PlanItem 來適應新的 TrainingSessionPage
                final tempPlanItem = PlanItem(
                  dayOfWeek: 0, // 臨時項目，星期設為 0 即可
                  exerciseName: widget.exercise.name,
                  sets: _sets.toString(),
                  weight: '', // 這裡還不知道重量，留空讓使用者在訓練時填寫
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingSessionPage(
                      // 傳遞一個只包含這一個動作的清單
                      planItems: [tempPlanItem], 
                      bodyPart: widget.bodyPart,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('開始訓練', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required int initialItem,
    String suffix = '',
    bool isSeconds = false,
  }) {
    return SizedBox(
      height: 120,
      child: CupertinoPicker(
        itemExtent: 40,
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        onSelectedItemChanged: onSelectedItemChanged,
        children: List<Widget>.generate(itemCount, (int index) {
          final value = isSeconds ? index * 10 : index + (suffix == '分' ? 0 : 1);
          return Center(child: Text('$value $suffix'));
        }),
      ),
    );
  }
}