import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


import '../services/database_helper.dart';
import './weight_trend_page.dart';
import '../models/exercise_model.dart'; // 【新增這

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
// in lib/pages/dashboard_home_page.dart -> _DashboardHomePageState

// 【還原】為不同肌群定義顏色，只保留您原有的項目
final Map<BodyPart, Color> _bodyPartColors = {
  BodyPart.chest: Colors.blue.shade400,
  BodyPart.back: Colors.green.shade400,
  BodyPart.legs: Colors.orange.shade400,
  BodyPart.shoulders: Colors.purple.shade400,
  BodyPart.biceps: Colors.red.shade300,  // 為二頭和三頭也加上顏色
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
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WeightTrendPage(account: widget.account)),
          );
          _loadSummaryData();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
    );
  }
}