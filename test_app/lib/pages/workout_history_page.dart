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
  late Future<List<WorkoutLog>> _logsFuture;
  List<WorkoutLog> _allLogs = [];
  List<WorkoutLog> _selectedLogs = [];
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _logsFuture = DatabaseHelper.instance.getWorkoutLogs().then((logs) {
      if (mounted) {
        setState(() {
          _allLogs = logs;
          _selectedLogs = _getLogsForDay(_selectedDay!);
        });
      }
      return logs;
    });
  }
  
  List<WorkoutLog> _getLogsForDay(DateTime day) {
    return _allLogs.where((log) => isSameDay(log.completedAt, day)).toList();
  }

  // --- 【修正】 ---
  // 為 `switch` 陳述式加上 BodyPart.back 的情況
  Color _getColorForBodyPart(BodyPart part) {
    switch (part) {
      case BodyPart.chest: return Colors.yellow.shade700;
      case BodyPart.legs: return Colors.red.shade700;
      case BodyPart.shoulders: return Colors.blue.shade700;
      case BodyPart.abs: return Colors.orange.shade700;
      case BodyPart.biceps: return Colors.green.shade700;
      case BodyPart.triceps: return Colors.purple.shade700;
      case BodyPart.back: return Colors.brown.shade700; // 為「背」新增一個顏色
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

          return Column(
            children: [
              TableCalendar<WorkoutLog>(
                locale: 'zh_TW',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
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
