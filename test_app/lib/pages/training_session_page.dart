// 訓練進行中的計時與計組頁面

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_log_model.dart';
import '../models/set_log_model.dart'; // 【新增】導入 SetLog
import './training_summary_page.dart';
import '../services/database_helper.dart';

class TrainingSessionPage extends StatefulWidget {
  final Exercise exercise;
  final int totalSets;
  final int restTimeInSeconds;
  final BodyPart bodyPart;

  const TrainingSessionPage({
    super.key,
    required this.exercise,
    required this.totalSets,
    required this.restTimeInSeconds,
    required this.bodyPart,
  });

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  Timer? _timer;
  int _currentSet = 1;
  int _countdownSeconds = 5;
  bool _isResting = false;
  bool _isPreparing = true; // 【修改】用一個更精確的變數名

  // 【新增】管理重量和次數輸入的控制器
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 【新增】一個 List 用來暫存每一組的數據
  final List<Map<String, dynamic>> _setsData = [];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          // 倒數結束後，將對應的狀態設為 false
          if (_isPreparing) {
            _isPreparing = false;
          }
          if (_isResting) {
            _isResting = false;
            // 休息結束後，自動填上上一組的數據方便修改
            if (_setsData.isNotEmpty) {
              _weightController.text = _setsData.last['weight'].toString();
              _repsController.text = _setsData.last['reps'].toString();
            }
          }
        });
      }
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      // 休息結束後，自動填上上一組的數據
      if (_setsData.isNotEmpty) {
        _weightController.text = _setsData.last['weight'].toString();
        _repsController.text = _setsData.last['reps'].toString();
      }
    });
  }

  void _finishSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 1. 記錄當前組數的數據
    _setsData.add({
      'setNumber': _currentSet,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'reps': int.tryParse(_repsController.text) ?? 0,
    });

    if (_currentSet < widget.totalSets) {
      // 2. 如果還沒達到總組數 -> 進入休息
      setState(() {
        _isResting = true;
        _currentSet++;
        _countdownSeconds = widget.restTimeInSeconds;
      });
      _startCountdown();
    } else {
      // 3. 如果已經完成所有組數 -> 儲存數據並結束
      final workoutLog = WorkoutLog(
        exerciseName: widget.exercise.name,
        totalSets: widget.totalSets,
        completedAt: DateTime.now(),
        bodyPart: widget.bodyPart,
      );
      final workoutLogId = await DatabaseHelper.instance.insertWorkoutLog(workoutLog);
      
      for (var setData in _setsData) {
        final setLog = SetLog(
          workoutLogId: workoutLogId,
          setNumber: setData['setNumber'],
          weight: setData['weight'],
          reps: setData['reps'],
        );
        await DatabaseHelper.instance.insertSetLog(setLog);
      }
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TrainingSummaryPage(log: workoutLog),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    if (_isPreparing) {
      statusText = '準備開始...';
    } else if (_isResting) {
      statusText = '休息中';
    } else {
      statusText = '第 $_currentSet / ${widget.totalSets} 組';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(statusText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),
              
              if (_isPreparing || _isResting)
                // 休息或準備時，顯示倒數計時器
                Text('$_countdownSeconds', style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold))
              else


                // 【修改】訓練中，顯示影像辨識的預留空間
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 60),
                            SizedBox(height: 12),
                            Text('即時動作辨識 (待開發)', style: TextStyle(color: Colors.white54, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              

              
               if (!_isPreparing && !_isResting)
                _buildTrainingInputFields(),

              const Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    if (_isResting)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skipRest,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                          child: const Text('跳過休息', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    if (_isResting) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isPreparing || _isResting) ? null : _finishSet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(77),
                          disabledForegroundColor: Colors.white.withAlpha(128),
                        ),
                        child: Text(_isResting ? '休息中...' : '完成第 $_currentSet 組', style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrainingInputFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '重量 (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              validator: (v) => v == null || v.isEmpty ? '請輸入' : null,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: TextFormField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: '次數 (Reps)'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              validator: (v) => v == null || v.isEmpty ? '請輸入' : null,
            ),
          ),
        ],
      ),
    );
  }
}