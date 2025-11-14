// 訓練日曆與歷史紀錄瀏覽頁面。

// lib/pages/workout_history_page.dart

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
  late Future<List<WorkoutLog>> _logsFuture;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _refreshLogs();
  }
  
  // 這個方法會觸發 FutureBuilder 重新讀取資料
  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = DatabaseHelper.instance.getWorkoutLogs();
    });
  }

  List<WorkoutLog> _getLogsForDay(DateTime day, List<WorkoutLog> allLogs) {
    return allLogs.where((log) => isSameDay(log.completedAt, day)).toList();
  }

  Color _getColorForBodyPart(BodyPart part) {
    switch (part) {
      case BodyPart.chest: return Colors.blue.shade400;
      case BodyPart.legs: return Colors.orange.shade400;
      case BodyPart.shoulders: return Colors.purple.shade400;
      case BodyPart.abs: return Colors.cyan.shade400;
      case BodyPart.biceps: return Colors.red.shade300;
      case BodyPart.triceps: return Colors.red.shade500;
      case BodyPart.back: return Colors.green.shade400;
    }
  }
Widget _buildLegendItem(Color color, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 讓 Row 只佔用它需要的寬度
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(name),
      ],
    );
  }
    Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      // 使用 Wrap Widget，如果一行放不下，它會自動換行，避免出錯
      child: Wrap(
        spacing: 16.0, // 每個項目之間的水平間距
        runSpacing: 8.0,   // 每一行之間的垂直間距
        alignment: WrapAlignment.center, // 置中對齊
        children: BodyPart.values.map((part) {
          // 遍歷所有 BodyPart 的值，為每一個都建立一個圖例項目
          return _buildLegendItem(_getColorForBodyPart(part), part.displayName);
        }).toList(),
      ),
    );
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

          final allLogs = snapshot.data ?? [];
          final selectedLogs = _getLogsForDay(_selectedDay!, allLogs);

          // 【修改】將整體佈局用 RefreshIndicator 包裹起來
          return RefreshIndicator(
            onRefresh: _refreshLogs, // 指定下拉時要執行的刷新方法
            child: ListView.builder(
              itemCount: selectedLogs.isEmpty ? 2 : selectedLogs.length + 1,
              itemBuilder: (context, index) {
                // 第一個項目永遠是日曆
                if (index == 0) {
                  return Card(
                // Card 會自動使用您在 main.dart 中定義好的主題樣式
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                clipBehavior: Clip.antiAlias, // 確保內容不會超出圓角
                child: Column(
                  children: [
                    TableCalendar<WorkoutLog>(
                      locale: 'zh_TW',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: (day) => _getLogsForDay(day, allLogs),
                      onDaySelected: (selectedDay, focusedDay) {
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
                        todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isNotEmpty) {
                            final colors = events.map((log) => _getColorForBodyPart(log.bodyPart)).toSet().toList();
                            return Positioned(bottom: 1, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: colors.map((color) => Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color))).toList()));
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildLegend(),
                    // 我們不再需要 Divider 和 SizedBox，因為 Card 本身就是一個分隔
                  ],
                ),
              );
            }

                if (selectedLogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: Text('這天沒有訓練紀錄')),
                  );
                }
                
                final log = selectedLogs[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForBodyPart(log.bodyPart),
                        child: Text('${log.totalSets}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(log.exerciseName),
                      subtitle: Text('完成於: ${DateFormat('HH:mm').format(log.completedAt)}'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}