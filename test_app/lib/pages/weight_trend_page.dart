// 顯示體重與 BMI 變化的詳細圖表頁面。

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/weight_log_model.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

// 【修正】移除了多餘的 exercise_model.dart 導入

class TrendPageData {
  final User? user;
  final List<WeightLog> logs;
  TrendPageData({required this.user, required this.logs});
}

enum TimeRange { week, month, threeMonths, year }

class WeightTrendPage extends StatefulWidget {
  final String account;
  const WeightTrendPage({super.key, required this.account});

  @override
  State<WeightTrendPage> createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends State<WeightTrendPage> {
  late Future<TrendPageData> _pageDataFuture;
  TimeRange _selectedRange = TimeRange.month;
  final List<bool> _isSelected = [false, true, false, false];
  bool _showBmi = false;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  Future<TrendPageData> _loadPageData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    final logs = await DatabaseHelper.instance.getWeightLogs();
    return TrendPageData(user: user, logs: logs);
  }

  List<WeightLog> _filterLogs(List<WeightLog> logs) {
    DateTime now = DateTime.now();
    DateTime cutoffDate;
    switch (_selectedRange) {
      case TimeRange.week:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.threeMonths:
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case TimeRange.year:
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
    }
    return logs.where((log) => log.createdAt.isAfter(cutoffDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('體重趨勢'),
      ),
      body: FutureBuilder<TrendPageData>(
        future: _pageDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('載入資料失敗: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.logs.isEmpty) {
            return const Center(
              child: Text(
                '目前沒有體重紀錄',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final pageData = snapshot.data!;
          final filteredLogs = _filterLogs(pageData.logs);

          if (filteredLogs.isEmpty) {
            return const Center(
              child: Text(
                '這個時間範圍內沒有紀錄',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final user = pageData.user;
          final double userHeight = double.tryParse(user?.height ?? '0') ?? 0;
          final double? goalWeight = double.tryParse(user?.goalWeight ?? '');

          final weightSpots = filteredLogs.reversed
              .map((log) => FlSpot(
                  log.createdAt.millisecondsSinceEpoch.toDouble(), log.weight))
              .toList();
          List<FlSpot> bmiSpots = [];
          if (userHeight > 0) {
            bmiSpots = filteredLogs.reversed.map((log) {
              final bmi =
                  log.weight / ((userHeight / 100) * (userHeight / 100));
              return FlSpot(
                  log.createdAt.millisecondsSinceEpoch.toDouble(), bmi);
            }).toList();
          }
          
          final List<double> allYValues = [...weightSpots.map((s) => s.y)];
          if (_showBmi) {
            allYValues.addAll(bmiSpots.map((s) => s.y));
          }
          final minY = allYValues.reduce((a, b) => a < b ? a : b);
          final maxY = allYValues.reduce((a, b) => a > b ? a : b);
          
          final double bottomTitleInterval = switch (_selectedRange) {
            TimeRange.week => const Duration(days: 2).inMilliseconds.toDouble(),
            TimeRange.month => const Duration(days: 7).inMilliseconds.toDouble(),
            TimeRange.threeMonths => const Duration(days: 30).inMilliseconds.toDouble(),
            TimeRange.year => const Duration(days: 90).inMilliseconds.toDouble(),
          };

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: ToggleButtons(
                  isSelected: _isSelected,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _isSelected.length; i++) {
                        _isSelected[i] = i == index;
                      }
                      _selectedRange = TimeRange.values[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  constraints:
                      const BoxConstraints(minHeight: 40.0, minWidth: 80.0),
                  children: const [ Text('1週'), Text('1個月'), Text('3個月'), Text('1年') ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Theme.of(context).colorScheme.primary, '體重 (kg)'),
                  if (_showBmi) ...[
                    const SizedBox(width: 20),
                    _buildLegendItem(Colors.orange.shade400, 'BMI'),
                  ],
                  const Spacer(),
                  const Text('顯示 BMI'),
                  const SizedBox(width: 4),
                  Switch(
                    value: _showBmi,
                    onChanged: (value) {
                      setState(() {
                        _showBmi = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: (minY / 10).floor() * 10 - 5,
                    maxY: (maxY / 10).ceil() * 10 + 5,
                    lineBarsData: [
                      _buildLineBarData(
                          weightSpots, Theme.of(context).colorScheme.primary),
                      if (_showBmi && bmiSpots.isNotEmpty)
                        _buildLineBarData(bmiSpots, Colors.orange.shade400),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 10,
                        ),
                      ),
                      bottomTitles: AxisTitles(sideTitles: _bottomTitles(bottomTitleInterval)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final barData = spot.bar;
                            String text;
                            if (barData.color == Colors.orange.shade400) {
                              text = 'BMI: ${spot.y.toStringAsFixed(1)}';
                            } else {
                              text = '體重: ${spot.y.toStringAsFixed(1)} kg';
                            }
                            return LineTooltipItem(text, const TextStyle(fontWeight: FontWeight.bold));
                          }).toList();
                        },
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (goalWeight != null)
                          HorizontalLine(
                            y: goalWeight,
                            color: const Color.fromARGB(128, 255, 255, 255),
                            strokeWidth: 2,
                            dashArray: [10, 6],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.only(left: 5, top: 5),
                              style: const TextStyle(
                                color: Color.fromARGB(179, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              labelResolver: (line) => '目標 ${line.y.toStringAsFixed(1)}kg',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '提醒：由於體重和 BMI 的數值範圍不同...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  LineChartBarData _buildLineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  SideTitles _bottomTitles(double interval) => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: interval,
        getTitlesWidget: (value, meta) {
          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 4,
            child: Text(
              DateFormat('M/d').format(date),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
      );
}