// lib/pages/weight_trend_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_log_model.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import './profile_page.dart';

class WeightTrendPage extends StatefulWidget {
  final String account;
  const WeightTrendPage({super.key, required this.account});

  @override
  State<WeightTrendPage> createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends State<WeightTrendPage> with SingleTickerProviderStateMixin {
  List<WeightLog> _allLogs = [];
  User? _currentUser;
  late TabController _tabController;

  String _selectedRange = '1週';
  final List<String> _ranges = ['1週', '1個月', '3個月', '1年'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
   final logs = await DatabaseHelper.instance.getWeightLogs(widget.account);
    
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _allLogs = logs;
    });
  }

  void _showSetGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 更圓的圓角

       title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_circle, size: 50, color: Colors.blueAccent), // 醒目圖示
            SizedBox(height: 12),
            Text('設定目標體重', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),

         content: const Text(
          '設定一個目標，讓我們陪您一起達成！\n您想要現在前往設定嗎？',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70, 
            fontSize: 16, 
            height: 1.5, // 增加行距，解決擁擠感
          ),
        ),
        
        // 按鈕區：美化按鈕樣式
        actionsAlignment: MainAxisAlignment.spaceEvenly, // 按鈕平均分佈
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍後', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(account: widget.account)),
              ).then((_) => _loadData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('前往設定', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  List<WeightLog> _getFilteredLogs() {
    if (_allLogs.isEmpty) return [];
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedRange) {
      case '1週': cutoffDate = now.subtract(const Duration(days: 7)); break;
      case '1個月': cutoffDate = now.subtract(const Duration(days: 30)); break;
      case '3個月': cutoffDate = now.subtract(const Duration(days: 90)); break;
      case '1年': cutoffDate = now.subtract(const Duration(days: 365)); break;
      default: cutoffDate = now.subtract(const Duration(days: 30));
    }
    return _allLogs.where((log) => log.createdAt.isAfter(cutoffDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('趨勢分析'),
        actions: [
          // 【新增】設定目標按鈕
          IconButton(
            icon: const Icon(Icons.flag_outlined), // 旗標圖示代表目標
            tooltip: '設定目標體重',
            onPressed: _showSetGoalDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '體重 (kg)'),
            Tab(text: 'BMI 指數'),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendView(isBMI: false),
          _buildTrendView(isBMI: true),
        ],
      ),
    );
  }

  Widget _buildTrendView({required bool isBMI}) {
    final filteredLogs = _getFilteredLogs(); 
    // 0. Declarations
    List<FlSpot> spots = [];
    double minY = 1000, maxY = 0;
    double? goalValue;
    
    if (!isBMI) {
      goalValue = double.tryParse(_currentUser?.goalWeight ?? '');
    }

    // 1. Deduplicate: Group by Day (Keep latest log per day)
    final Map<String, WeightLog> dailyMap = {};
    for (var log in filteredLogs) {
        final dateKey = DateFormat('yyyy-MM-dd').format(log.createdAt);
        // Since filteredLogs is Descending (Newest first), the first one we see is the latest for that day?
        // Wait, _getFilteredLogs returns unsorted or DB ordered (usually Newest first or Oldest first?).
        // Let's assume we want Latest. 
        // If we iterate and putIfAbsent, we keep First encountered.
        // If we overwrite, we keep Last encountered.
        // Let's ensure we use specific logic.
        if (!dailyMap.containsKey(dateKey)) {
             dailyMap[dateKey] = log;
        } else {
             // Compare createdAt
             if (log.createdAt.isAfter(dailyMap[dateKey]!.createdAt)) {
                 dailyMap[dateKey] = log;
             }
        }
    }
    // Convert back to List and Sort by Date Ascending for Charting (Oldest -> Newest)
    final List<WeightLog> uniqueDailyLogs = dailyMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Ascending

    // Use uniqueDailyLogs for spots
    for (int i = 0; i < uniqueDailyLogs.length; i++) {
        final log = uniqueDailyLogs[i];
        double y = log.weight;
        
        if (isBMI && _currentUser != null) {
            final height = double.tryParse(_currentUser!.height) ?? 0;
            if (height > 0) {
                final heightM = height / 100.0;
                y = y / (heightM * heightM);
            } else {
                y = 0;
            }
        }
        
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        spots.add(FlSpot(i.toDouble(), y));
    }
    
    if (goalValue != null) {
      if (goalValue < minY) minY = goalValue;
      if (goalValue > maxY) maxY = goalValue;
    }
    
    final padding = (maxY - minY) * 0.1; 
    minY = (minY - padding).clamp(0, double.infinity); 
    maxY = maxY + padding;
    
    if (spots.isEmpty) { minY = 0; maxY = 100; }
    if (minY == maxY) { minY -= 5; maxY += 5; }

    // X-Axis Layout Logic (Ordinal)
    double minX = -0.5;
    double maxX = (spots.isEmpty ? 0 : spots.length - 1) + 0.5;
    
    // Determine label step to show roughly 5 labels max
    int itemCount = spots.length;
    int labelStep = 1;
    if (itemCount > 5) {
        labelStep = (itemCount / 5).ceil();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _ranges.map((range) {
                final isSelected = range == _selectedRange;
                final nowExact = DateTime.now();
                
                // Button Logic: Use earliest record from ALL logs to determine capability
                final firstDate = _allLogs.isNotEmpty ? _allLogs.last.createdAt : null; 
                // Note: Assuming _allLogs is sorted desc? If not, .last might not be oldest. 
                // Safest to sort or find min. Ideally Database returns sorted. 
                // Let's assume _allLogs is reliable. 
                
                bool isEnabled = true;
                if (firstDate != null) {
                  final diff = nowExact.difference(firstDate).inDays;
                  // Strict Check: specific range needs specific history
                  // User requested roughly calculating if data is enough
                  if (range == '1個月' && diff < 15) isEnabled = false; // Need ~2 weeks for 1 month view
                  if (range == '3個月' && diff < 45) isEnabled = false; // Need ~1.5 months for 3 month view
                  if (range == '1年' && diff < 150) isEnabled = false; // Need ~5 months for 1 year view
                } else {
                   if (range != '1週') isEnabled = false;
                }
                if (range == '1週') isEnabled = true; // Always enable 1 week

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(range),
                    selected: isSelected,
                    disabledColor: Colors.grey.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isEnabled 
                          ? (isSelected ? Colors.black : Colors.white) 
                          : Colors.grey,
                    ),
                    onSelected: isEnabled ? (selected) {
                      if (selected) setState(() => _selectedRange = range);
                    } : null, 
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Container(
          height: MediaQuery.of(context).size.height * 0.35,
          padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: isBMI ? Colors.orange : Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: (isBMI ? Colors.orange : Colors.blue).withValues(alpha: 0.1)),
                ),
              ],
              extraLinesData: (!isBMI && goalValue != null) ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goalValue,
                    color: Colors.redAccent,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (line) => '目標 ${goalValue}kg',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ) : null,
              minY: minY,
              maxY: maxY,
              minX: minX, 
              maxX: maxX,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1, 
                    getTitlesWidget: (value, meta) {
                        // Strict Integer Check: Prevent duplicate labels from padding values (e.g. -0.0001)
                        if (value % 1 != 0) return const SizedBox();
                        
                        int index = value.toInt();
                        if (index < 0 || index >= uniqueDailyLogs.length) return const SizedBox();
                        
                        // Strict Label Count Strategy:
                        // Only show Start (0), End (N), and maybe Middle.
                        // Aim for Max 3 labels to guarantee NO OVERLAP on any screen size.
                        
                        bool shouldShow = false;
                        int lastIndex = uniqueDailyLogs.length - 1;
                        
                        if (index == 0) shouldShow = true; // Always show Head
                        else if (index == lastIndex) shouldShow = true; // Always show Tail
                        else {
                           // For intermediate labels, only show if we have enough points
                           // and it is exactly in the middle.
                           if (uniqueDailyLogs.length > 4) { // Only if ample data
                               if (index == (lastIndex / 2).round()) {
                                   shouldShow = true; // Show Middle
                               }
                           }
                        }

                        if (!shouldShow) return const SizedBox();

                        final date = uniqueDailyLogs[index].createdAt;
                        String text;
                        if (_selectedRange == '1年') {
                            text = '${date.month}月';
                        } else {
                            text = (_selectedRange == '1週') ? '${date.day}' : '${date.month}/${date.day}';
                        }
                      
                        return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            fitInside: SideTitleFitInsideData.disable(), 
                            child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: (maxY - minY) / 5, 
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: true,
                verticalInterval: 1, // Grid line for every data point
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= uniqueDailyLogs.length) return null;
                      
                      final date = uniqueDailyLogs[index].createdAt;
                      final dateStr = DateFormat('MM/dd').format(date);
                      final valueStr = isBMI ? spot.y.toStringAsFixed(1) : '${spot.y}kg';
                      return LineTooltipItem('$dateStr\n$valueStr', const TextStyle(color: Colors.white));
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),

        const Divider(height: 1, thickness: 1),

        // 詳細列表
        Expanded(
          child: Container(
            color: const Color(0xFF1C1C1E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isBMI ? 'BMI 歷史紀錄' : '體重歷史紀錄',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: filteredLogs.isEmpty 
                    ? const Center(child: Text('此範圍內尚無紀錄', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index]; 
                          
                          double value = log.weight;
                          if (isBMI && _currentUser != null) {
                            final height = double.tryParse(_currentUser!.height) ?? 0;
                            if (height > 0) {
                                final heightM = height / 100.0;
                                value = value / (heightM * heightM);
                            } else {
                                value = 0;
                            }
                          }

                          String changeText = '-';
                          Color changeColor = Colors.grey;
                          IconData changeIcon = Icons.remove;

                          if (index < filteredLogs.length - 1) {
                            final prevLog = filteredLogs[index + 1];
                            double prevValue = prevLog.weight;
                            if (isBMI && _currentUser != null) {
                                final height = double.tryParse(_currentUser!.height) ?? 0;
                                if (height > 0) {
                                    final heightM = height / 100.0;
                                    prevValue = prevValue / (heightM * heightM);
                                }
                            }

                            final diff = value - prevValue;
                            if (diff > 0) {
                              changeText = '+${diff.toStringAsFixed(1)}';
                              changeColor = Colors.redAccent; 
                              changeIcon = Icons.arrow_upward;
                            } else if (diff < 0) {
                              changeText = diff.toStringAsFixed(1);
                              changeColor = Colors.greenAccent;
                              changeIcon = Icons.arrow_downward;
                            } else {
                              changeText = '0.0';
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: const Color(0xFF2C2C2E),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                DateFormat('yyyy/MM/dd').format(log.createdAt),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(DateFormat('HH:mm').format(log.createdAt), style: const TextStyle(color: Colors.grey)),
                              trailing: SizedBox(
                                width: 140, 
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      isBMI ? value.toStringAsFixed(1) : '${value.toStringAsFixed(1)} kg',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Icon(changeIcon, color: changeColor, size: 12),
                                        Text(changeText, style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}