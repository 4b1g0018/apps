// lib/pages/training_session_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_log_model.dart';
import '../models/set_log_model.dart';
import '../models/plan_item_model.dart'; // 導入課表項目
import './training_summary_page.dart';
import '../services/database_helper.dart';

class TrainingSessionPage extends StatefulWidget {
  // 【核心修正】改為接收動作清單 (PlanItem)
  final List<PlanItem> planItems;
  final BodyPart bodyPart;
  final int initialIndex; // 為了相容性保留，或者可以從 planItems 推導

  const TrainingSessionPage({
    super.key,
    required this.planItems,
    required this.bodyPart,
    this.initialIndex = 0, // 預設從第 0 個開始
  });

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  Timer? _timer;
  
  // 追蹤目前正在進行第幾個動作
  int _currentExerciseIndex = 0;

  // 當前動作的狀態
  int _currentSet = 1;
  int _totalSets = 3; 
  int _countdownSeconds = 5;
  int _restTimeInSeconds = 60; 

  bool _isResting = false;
  bool _isPreparing = true;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _setsData = [];

  @override
  void initState() {
    super.initState();
   _currentExerciseIndex = widget.initialIndex;
    _initCurrentExercise();
  }

  // 初始化當前動作
  void _initCurrentExercise() {
    final currentItem = widget.planItems[_currentExerciseIndex];
    setState(() {
      _currentSet = 1;
      _setsData.clear();
      // 嘗試預填重量
      _weightController.text = currentItem.weight;
      _repsController.text = ''; 
      
      // 解析組數 (預設 3)
      _totalSets = int.tryParse(currentItem.sets) ?? 3;
      
      _isPreparing = true;
      _isResting = false;
      _countdownSeconds = 5;
    });
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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          if (_isPreparing) _isPreparing = false;
          if (_isResting) {
            _isResting = false;
             // 休息結束，預填上一組數據
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
       if (_setsData.isNotEmpty) {
          _weightController.text = _setsData.last['weight'].toString();
          _repsController.text = _setsData.last['reps'].toString();
       }
    });
  }

  void _finishSet() async {
    if (!_formKey.currentState!.validate()) return;
    
    _setsData.add({
      'setNumber': _currentSet,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'reps': int.tryParse(_repsController.text) ?? 0,
    });

    if (_currentSet < _totalSets) {
      setState(() {
        _isResting = true;
        _currentSet++;
        _countdownSeconds = _restTimeInSeconds; 
      });
      _startCountdown();
    } else {
      // --- 完成當前動作的所有組數 ---
      await _saveCurrentExerciseData();

      // 檢查是否還有下一個動作
      if (_currentExerciseIndex < widget.planItems.length - 1) {
        // 還有動作，顯示對話框
        if (!mounted) return;
        _showNextExerciseDialog();
      } else {
        // 全部完成！
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恭喜！今日課表全部完成！'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _saveCurrentExerciseData() async {
    final currentItem = widget.planItems[_currentExerciseIndex];
    
    final workoutLog = WorkoutLog(
      exerciseName: currentItem.exerciseName,
      totalSets: _totalSets,
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
  }

  Future<void> _showNextExerciseDialog() async {
    final nextItem = widget.planItems[_currentExerciseIndex + 1];
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('動作完成！'),
        content: Text('下一個動作：${nextItem.exerciseName}\n預設組數：${nextItem.sets} 組'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(width: double.infinity,
          child:ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentExerciseIndex++;
              });
              _initCurrentExercise(); // 初始化下一個動作
            },
           style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('開始下一個動作', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.planItems[_currentExerciseIndex];
    
    String statusText;
    if (_isPreparing) {
      statusText = '準備開始...';
    } else if (_isResting) {
      statusText = '休息中';
    } else {
      statusText = '第 $_currentSet / $_totalSets 組';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(currentItem.exerciseName),
            Text(
              '動作 ${_currentExerciseIndex + 1} / ${widget.planItems.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(statusText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),
              
              if (_isPreparing || _isResting)
                Expanded(child: Center(child: Text('$_countdownSeconds', style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold))))
              else
                 // 使用空的 Expanded 佔位，取代原本的影像辨識區塊
                 const Expanded(child: SizedBox()),

              if (!_isPreparing && !_isResting)
                Padding(padding: const EdgeInsets.only(top: 24.0), child: _buildTrainingInputFields()),

              const Spacer(),
              Row(
                children: [
                  if (_isResting)
                    Expanded(child: OutlinedButton(onPressed: _skipRest, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)), child: const Text('跳過休息', style: TextStyle(fontSize: 20)))),
                  if (_isResting) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isPreparing || _isResting) ? null : _finishSet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(77),
                        disabledForegroundColor: Colors.white.withAlpha(128),
                      ),
                      child: Text(_isResting ? '休息中...' : '完成第 $_currentSet 組', style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrainingInputFields() {
    return Row(children: [Expanded(child: TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: '重量 (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24), validator: (v) => v == null || v.isEmpty ? '請輸入' : null)), const SizedBox(width: 24), Expanded(child: TextFormField(controller: _repsController, decoration: const InputDecoration(labelText: '次數 (Reps)'), keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24), validator: (v) => v == null || v.isEmpty ? '請輸入' : null))]);
  }
}