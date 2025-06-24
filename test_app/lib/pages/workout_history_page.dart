// lib/pages/workout_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/workout_log_model.dart';
import '../models/exercise_model.dart';
import '../services/database_helper.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  // --- 狀態變數 ---
  late Future<List<WorkoutLog>> _logsFuture; // 我們只用一個 Future 來處理非同步載入
  List<WorkoutLog> _allLogs = []; // 備份從資料庫讀取的所有紀錄
  List<WorkoutLog> _selectedLogs = []; // 儲存被選中日期的紀錄
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // 頁面一載入，就觸發資料庫讀取
    // 我們使用 .then() 來確保在資料讀取完成後，才去更新 UI 狀態
    _logsFuture = DatabaseHelper.instance.getWorkoutLogs().then((logs) {
      // 檢查 Widget 是否還存在於畫面上，這是處理非同步操作的好習慣
      if (mounted) { 
        setState(() {
          _allLogs = logs;
          _selectedLogs = _getLogsForDay(_selectedDay!);
        });
      }
      return logs;
    });
  }
  
  // 使用 isSameDay 來安全地比較日期，這個方法來自 table_calendar 套件
  List<WorkoutLog> _getLogsForDay(DateTime day) {
    return _allLogs.where((log) => isSameDay(log.completedAt, day)).toList();
  }

  // 根據部位回傳顏色
  Color _getColorForBodyPart(BodyPart part) {
    switch (part) {
      case BodyPart.chest: return Colors.yellow.shade700;
      case BodyPart.legs: return Colors.red.shade700;
      case BodyPart.shoulders: return Colors.blue.shade700;
      case BodyPart.abs: return Colors.orange.shade700;
      case BodyPart.biceps: return Colors.green.shade700;
      case BodyPart.triceps: return Colors.purple.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練日曆'),
        centerTitle: true,
      ),
      // 我們用 FutureBuilder 來優雅地處理初始載入的「轉圈圈」畫面
      body: FutureBuilder<List<WorkoutLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          // 當資料還在載入時，顯示進度條
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 如果載入出錯，顯示錯誤訊息
          if (snapshot.hasError) {
            return Center(child: Text('讀取資料時發生錯誤: ${snapshot.error}'));
          }

          // 當資料成功載入後，我們才建立日曆和列表的畫面
          return Column(
            children: [
              TableCalendar<WorkoutLog>(
                locale: 'zh_TW', // 確保 main.dart 中已初始化
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                
                // 事件加載器，用來告訴日曆哪幾天有事件（訓練紀錄）
                eventLoader: _getLogsForDay,
                
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedLogs = _getLogsForDay(selectedDay);
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                
                // --- 自訂日曆外觀 ---
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  // 自訂彩色圓點標記
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      final colors = events.map((log) => _getColorForBodyPart(log.bodyPart)).toSet();
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: colors.map((color) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          )).toList(),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const Divider(),
              
              // --- 下方顯示當天紀錄的列表 ---
              Expanded(
                child: _selectedLogs.isEmpty
                    ? const Center(child: Text('這天沒有訓練紀錄'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _selectedLogs.length,
                        itemBuilder: (context, index) {
                          final log = _selectedLogs[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorForBodyPart(log.bodyPart),
                                child: Text(
                                  '${log.totalSets}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(log.exerciseName),
                              subtitle: Text('完成於: ${DateFormat('HH:mm').format(log.completedAt)}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
