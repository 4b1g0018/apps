// 「開始訓練」流程的第三步：設定訓練參數（組數、休息時間）。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import './training_session_page.dart';

class ExerciseSetupPage extends StatefulWidget {
  final Exercise exercise;
  final BodyPart bodyPart; // 接收從上一頁傳來的 bodyPart

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
          Text(
            '動作設定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade500, size: 50),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.exercise.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '訓練參數',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingSessionPage(
                      exercise: widget.exercise,
                      totalSets: _sets,
                      restTimeInSeconds: (_restMinutes * 60) + _restSeconds,
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
      height: 150,
      child: CupertinoPicker(
        itemExtent: 40.0,
        onSelectedItemChanged: onSelectedItemChanged,
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        children: List<Widget>.generate(itemCount, (index) {
          final text = isSeconds ? '${index * 10}' : '${index + (suffix == '分' ? 0 : 1)}';
          return Center(
            child: Text('$text $suffix', style: const TextStyle(fontSize: 20)),
          );
        }),
      ),
    );
  }
}
