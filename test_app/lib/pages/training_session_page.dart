// 訓練過程頁面，實時計時與組數追蹤。

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_log_model.dart';
import '../models/set_log_model.dart';
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
  bool _isPreparing = true;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
          if (_isPreparing) {
            _isPreparing = false;
          }
          if (_isResting) {
            _isResting = false;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _setsData.add({
      'setNumber': _currentSet,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'reps': int.tryParse(_repsController.text) ?? 0,
    });

    if (_currentSet < widget.totalSets) {
      setState(() {
        _isResting = true;
        _currentSet++;
        _countdownSeconds = widget.restTimeInSeconds;
      });
      _startCountdown();
    } else {
      // 完成所有組數
      final workoutLog = WorkoutLog(
        exerciseName: widget.exercise.name,
        totalSets: widget.totalSets,
        completedAt: DateTime.now(),
        bodyPart: widget.bodyPart,
      );
      final workoutLogId = await DatabaseHelper.instance.insertWorkoutLog(workoutLog);
      
      // 使用 copyWith 建立一個包含 ID 的新物件
      final savedLog = workoutLog.copyWith(id: workoutLogId);

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
      
      // 將包含了 ID 的 savedLog 傳遞下去
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TrainingSummaryPage(log: savedLog),
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 40.0, left: 24.0, right: 24.0, top: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(statusText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),
              
              // 根據狀態顯示計時器，或影像辨識區塊
             if (_isPreparing || _isResting)
                // 休息或準備時，顯示倒數計時器
                Expanded(
                  child: Center(
                    child: Text('$_countdownSeconds',
                        style: const TextStyle(
                            fontSize: 120, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                // 【修改】我們移除了影像辨識區塊，
                // 換成一個空的 Expanded 來彈性地佔用空間，
                // 這樣可以讓下方的輸入框和按鈕保持在正確的位置。
                const Expanded(
                  child: SizedBox(),
                ),
                
              
              // 如果正在訓練，顯示輸入框
              if (!_isPreparing && !_isResting)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: _buildTrainingInputFields(),
                ),

              const Spacer(), // 把按鈕推到下面

              // 按鈕區塊
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrainingInputFields() {
    return Row(
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
    );
  }
}