// 訓練日曆，用以查詢過去的訓練紀錄。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/workout_log_model.dart';
import '../models/exercise_model.dart';
import '../services/database_helper.dart';

class WorkoutHistoryPage extends StatefulWidget {
  final String account;
  const WorkoutHistoryPage({super.key, required this.account});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  // 我們不再需要 _selectedLogs，因為它會在 build 方法中即時產生
  late Future<List<WorkoutLog>> _logsFuture;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // initState 只負責觸發資料庫讀取，不做其他處理
    _logsFuture = DatabaseHelper.instance.getWorkoutLogs();
  }
  
  // 這個方法維持不變，它會被 TableCalendar 使用
  List<WorkoutLog> _getLogsForDay(DateTime day, List<WorkoutLog> allLogs) {
    return allLogs.where((log) => isSameDay(log.completedAt, day)).toList();
  }

  Color _getColorForBodyPart(BodyPart part) {
    // 您的顏色對應邏輯維持不變
    switch (part) {
      case BodyPart.chest: return Colors.yellow.shade700;
      case BodyPart.legs: return Colors.red.shade700;
      case BodyPart.shoulders: return Colors.blue.shade700;
      case BodyPart.abs: return Colors.orange.shade700;
      case BodyPart.biceps: return Colors.green.shade700;
      case BodyPart.triceps: return Colors.purple.shade700;
      case BodyPart.back: return Colors.brown.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練日曆'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<WorkoutLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('讀取資料時發生錯誤: ${snapshot.error}'));
          }

          // 我們在 build 方法中才處理所有資料
          final allLogs = snapshot.data ?? [];
          final selectedLogs = _getLogsForDay(_selectedDay!, allLogs);

          return Column(
            children: [
              TableCalendar<WorkoutLog>(
                locale: 'zh_TW',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                // eventLoader 現在需要傳入 allLogs
                eventLoader: (day) => _getLogsForDay(day, allLogs),
                onDaySelected: (selectedDay, focusedDay) {
                  // 【修改】onDaySelected 現在只負責更新「選中的日期」
                  // build 方法會自動根據新日期來刷新列表
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
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
              Expanded(
                child: selectedLogs.isEmpty
                    ? const Center(child: Text('這天沒有訓練紀錄'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: selectedLogs.length,
                        itemBuilder: (context, index) {
                          final log = selectedLogs[index];
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