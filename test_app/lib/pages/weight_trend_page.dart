// 顯示體重與 BMI 變化的詳細圖表頁面。

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/weight_log_model.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

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

  Future<void> _showAddWeightDialog() async {
    final weightController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // 【排版修正】將 AlertDialog 的內容展開，方便閱讀
        return AlertDialog(
          title: const Text('記錄今日體重'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: weightController,
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
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('儲存'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  final weight = double.parse(weightController.text);
                  final newLog =
                      WeightLog(weight: weight, createdAt: DateTime.now());
                  await DatabaseHelper.instance.insertWeightLog(newLog);
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('體重紀錄已儲存！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _pageDataFuture = _loadPageData();
                  });
                }
              },
            ),
          ],
        );
      },
    );
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
          if (!snapshot.hasData) {
            return const Center(child: Text('沒有資料'));
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
                  children: const [
                    Text('1週'),
                    Text('1個月'),
                    Text('3個月'),
                    Text('1年'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLegend(),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      _buildLineBarData(
                          weightSpots, Theme.of(context).colorScheme.primary),
                      if (bmiSpots.isNotEmpty)
                        _buildLineBarData(bmiSpots, Colors.orange.shade400),
                    ],
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
                            return LineTooltipItem(
                              text,
                              // ignore: prefer_const_constructors
                              TextStyle(
                                color: barData.color,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                      ),
                      bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade700),                      
                    ),
                    extraLinesData: ExtraLinesData(
  horizontalLines: [
    HorizontalLine(
      y: 60.0,
      // 【修改】使用 Color.fromARGB 來設定顏色與透明度
      color: const Color.fromARGB(128, 255, 255, 255), // 約 50% 透明度的白色
      strokeWidth: 2,
      dashArray: [10, 6],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 5, top: 5),
        // 【修改】這裡也可以變成 const 了，因為顏色現在是常數
        style: const TextStyle(
          color: Color.fromARGB(179, 255, 255, 255), // 約 70% 透明度的白色
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        labelResolver: (line) => '目標 ${line.y.toStringAsFixed(1)}kg',
      ),
    ),
  ],
),
                  )
  ),
),

              const SizedBox(height: 16),
              const Text(
                '提醒：由於體重和 BMI 的數值範圍不同，在同一個 Y 軸上，BMI 曲線的起伏看起來會比較平緩。您可以觸控圖表上的點來查看精確數值。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeightDialog,
        tooltip: '記錄體重',
        child: const Icon(Icons.monitor_weight_outlined),
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Theme.of(context).colorScheme.primary, '體重 (kg)'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.orange.shade400, 'BMI'),
      ],
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

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(DateFormat('M/d').format(date)),
          );
        },
      );
}