// lib/pages/dashboard_home_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/weight_log_model.dart';
import '../services/database_helper.dart';
import './weight_trend_page.dart';
import '../models/exercise_model.dart';

class DashboardHomePage extends StatefulWidget {
  final String account;
  const DashboardHomePage({super.key, required this.account});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  // 狀態變數
  double? _latestWeight;
  double? _weightChange;
  int _workoutsThisWeek = 0;
  Map<BodyPart, double> _bodyPartDistribution = {};

  // 為不同肌群定義顏色
  final Map<BodyPart, Color> _bodyPartColors = {
    BodyPart.chest: Colors.blue.shade400,
    BodyPart.back: Colors.green.shade400,
    BodyPart.legs: Colors.orange.shade400,
    BodyPart.shoulders: Colors.purple.shade400,
    BodyPart.biceps: Colors.red.shade300,
    BodyPart.triceps: Colors.red.shade500,
    BodyPart.abs: Colors.cyan.shade400,
  };

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    _loadWeightData();
    _loadWorkoutData();
  }

  Future<void> _loadWeightData() async {
    final weightLogs = await DatabaseHelper.instance.getWeightLogs();
    if (!mounted) return;
    
    if (weightLogs.isEmpty) {
      setState(() {
        _latestWeight = null;
        _weightChange = null;
      });
      return;
    }

    final latestWeight = weightLogs[0].weight;
    double? weightChange;
    if (weightLogs.length > 1) {
      final previousWeight = weightLogs[1].weight;
      weightChange = latestWeight - previousWeight;
    }
    setState(() {
      _latestWeight = latestWeight;
      _weightChange = weightChange;
    });
  }

  Future<void> _loadWorkoutData() async {
    final workoutLogs = await DatabaseHelper.instance.getWorkoutLogs();
    if (!mounted) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final thisWeekLogs = workoutLogs.where((log) {
      final completedAt = log.completedAt;
      return (completedAt.isAfter(startOfWeek) || completedAt.isAtSameMomentAs(startOfWeek)) && completedAt.isBefore(endOfWeek);
    }).toList();
    
    if (thisWeekLogs.isEmpty) {
      setState(() {
        _workoutsThisWeek = 0;
        _bodyPartDistribution = {};
      });
      return;
    }

    Map<BodyPart, int> counts = {};
    for (var log in thisWeekLogs) {
      counts[log.bodyPart] = (counts[log.bodyPart] ?? 0) + 1;
    }

    Map<BodyPart, double> distribution = {};
    counts.forEach((part, count) {
      distribution[part] = (count / thisWeekLogs.length) * 100;
    });

    setState(() {
      _workoutsThisWeek = thisWeekLogs.length;
      _bodyPartDistribution = distribution;
    });
  }

  Future<void> _showAddWeightDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _AddWeightDialog(
        onSave: () {
          _loadSummaryData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummaryData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummaryData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWorkoutSummaryCard(),
            const SizedBox(height: 16),
            _buildWeightSummaryCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutSummaryCard() {
    final List<PieChartSectionData> sections = [];
    _bodyPartDistribution.forEach((part, percentage) {
      sections.add(
        PieChartSectionData(
          color: _bodyPartColors[part] ?? Colors.grey,
          value: percentage,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: sections.isEmpty
                  ? const Center(child: Text('本週無紀錄', style: TextStyle(color: Colors.grey)))
                  : PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 25,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本週訓練摘要',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$_workoutsThisWeek',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: ' 次',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummaryCard() {
    final changeValue = _weightChange;
    final changeColor = (changeValue == null) ? Colors.grey : (changeValue >= 0 ? Colors.red.shade400 : Colors.green.shade400);
    final changeIcon = (changeValue == null) ? Icons.remove : (changeValue >= 0 ? Icons.arrow_upward : Icons.arrow_downward);
    final changeText = changeValue != null ? changeValue.abs().toStringAsFixed(1) : '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WeightTrendPage(account: widget.account)),
                  );
                  _loadSummaryData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('體重', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _latestWeight?.toStringAsFixed(1) ?? '--',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Text('kg', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(changeIcon, color: changeColor, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                changeText,
                                style: TextStyle(color: changeColor, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.primary.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                onPressed: _showAddWeightDialog,
                tooltip: '記錄體重',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWeightDialog extends StatefulWidget {
  final VoidCallback onSave;
  const _AddWeightDialog({required this.onSave});

  @override
  State<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<_AddWeightDialog> {
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(DateTime.now(), _selectedDate);
    final formattedDate =
        isToday ? '今天' : DateFormat('yyyy/MM/dd').format(_selectedDate);

    return AlertDialog(
      title: const Text('記錄體重'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '體重 (kg)',
                suffixText: 'kg',
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? '請輸入體重'
                  : (double.tryParse(v) == null ? '請輸入有效的數字' : null),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('日期'),
              trailing: Text(formattedDate),
              onTap: () => _selectDate(context),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('儲存'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final weight = double.parse(_weightController.text);
              final newLog = WeightLog(
                weight: weight,
                createdAt: _selectedDate,
              );
              await DatabaseHelper.instance.insertWeightLog(newLog);

              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('體重紀錄已儲存！'),
                  backgroundColor: Colors.green,
                ),
              );
              widget.onSave();
            }
          },
        ),
      ],
    );
  }
}