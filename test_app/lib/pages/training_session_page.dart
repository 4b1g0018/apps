// lib/pages/training_session_page.dart

// 引入 dart:async 來使用 Timer (計時器)
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_log_model.dart';
import './training_summary_page.dart';
import '../services/database_helper.dart';

// --- 頁面主體：TrainingSessionPage ---
// 這是一個 StatefulWidget，因為頁面上的計時器、組數等狀態會不斷改變。
class TrainingSessionPage extends StatefulWidget {
  // 從上一個頁面接收訓練所需的所有參數
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

// --- 頁面狀態管理 ---
class _TrainingSessionPageState extends State<TrainingSessionPage> {
  // --- 狀態變數 ---
  Timer? _timer; // 用來控制倒數計時的 Timer 物件
  int _currentSet = 1; // 目前的組數
  int _countdownSeconds = 5; // 初始的準備倒數時間
  bool _isResting = false; // 是否正在休息的標記
  bool _isStarted = false; // 是否已經開始訓練 (用於顯示準備倒數)

  // --- initState: 當頁面第一次被建立時會呼叫的方法 ---
  @override
  void initState() {
    super.initState();
    // 頁面一載入，就開始準備倒數
    _startCountdown();
  }

  // --- dispose: 當頁面被銷毀時會呼叫的方法 ---
  // 這是一個好習慣，在頁面結束時，要取消計時器，避免記憶體洩漏。
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- 核心邏輯：開始倒數 ---
  void _startCountdown() {
    // 標記訓練已開始 (顯示 "準備開始")
    setState(() => _isStarted = true);

    // `Timer.periodic` 會每隔一段時間（這裡設為 1 秒）就執行一次函式。
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        // 如果倒數還沒結束，就將秒數減 1。
        setState(() {
          _countdownSeconds--;
        });
      } else {
        // 如果倒數結束
        timer.cancel(); // 停止目前的計時器
        setState(() {
          // 根據目前是否在休息，來決定下一步要做什麼
          if (_isResting) {
            // 如果是休息結束，代表要開始下一組訓練
            _isResting = false;
          } else {
            // 如果是準備倒數結束，就正式進入第一組訓練
            _isStarted = false;
          }
        });
      }
    });
  }

  // --- 核心邏輯：完成一組訓練 ---
  void _finishSet() async {
    //新增非同步 （存取資料庫）
    if (_currentSet < widget.totalSets) {
      // 如果還沒達到總組數
      setState(() {
        _isResting = true; // 進入休息狀態
        _currentSet++; // 組數加 1
        _countdownSeconds = widget.restTimeInSeconds; // 設定休息倒數時間
      });
      _startCountdown(); // 開始休息倒數
    } else {
      // --- 如果已經完成所有組數 ---
      // 建立一個訓練紀錄物件
      // 建立 WorkoutLog 物件時，把 bodyPart 也加進去
      final workoutLog = WorkoutLog(
        exerciseName: widget.exercise.name,
        totalSets: widget.totalSets,
        completedAt: DateTime.now(),
        bodyPart: widget.bodyPart, // 接力棒的最後一站！
      );

      //寫入訓練紀錄
      await DatabaseHelper.instance.insertWorkoutLog(workoutLog);
      if (!mounted) return; //非同步要檢查頁面

      // 導向總結頁面
      // 使用 `pushReplacement`，它會用新頁面「取代」目前這個頁面。
      // 這樣使用者就不會從總結頁面按返回鍵，又回到計時頁面了。
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TrainingSummaryPage(log: workoutLog),
        ),
      );
    }
  }

  // --- UI 畫面繪製 ---
  @override
  Widget build(BuildContext context) {
    // 根據不同狀態，決定畫面上方要顯示的標題文字
    String statusText;
    if (_isStarted) {
      statusText = '準備開始...';
    } else if (_isResting) {
      statusText = '休息中';
    } else {
      statusText = '第 $_currentSet / ${widget.totalSets} 組';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        // 我們用 `automaticallyImplyLeading: false` 來隱藏預設的返回按鈕，
        // 強制使用者必須透過完成訓練或特定按鈕才能離開。
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 狀態標題 ---
            Text(
              statusText,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 20),

            // --- 倒數計時器 或 訓練提示 ---
            // 如果正在倒數 (準備或休息中)
            if (_isStarted || _isResting)
              Text(
                '$_countdownSeconds',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                ),
              )
            // 如果正在訓練中
            else
              const Text(
                '訓練中',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.green, //用顏色區分狀態
                ),
              ),

            const Spacer(), // 把按鈕推到下面
            // --- 按鈕區塊 ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 如果正在倒數，按鈕就設為禁用狀態 (顯示為灰色)。
                  onPressed: (_isStarted || _isResting) ? null : _finishSet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // 如果按鈕被禁用，我們讓它呈現灰色。
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _isResting ? '休息中...' : '完成一組',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
