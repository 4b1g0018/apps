// lib/pages/dashboard_home_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/weight_log_model.dart';
import '../models/user_model.dart';
import '../models/plan_item_model.dart';
import '../models/plan_item_model.dart';
import '../services/database_helper.dart';
import './weight_trend_page.dart';
import '../models/exercise_model.dart';
import './plan_editor_page.dart'; 
import './training_session_page.dart';

class DashboardHomePage extends StatefulWidget {
  final String account;
  const DashboardHomePage({super.key, required this.account});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  User? _currentUser;
  double? _latestWeight;
  double? _weightChange;
  int _workoutsThisWeek = 0;
  Map<BodyPart, double> _bodyPartDistribution = {};
  
// 【新增】課表相關狀態
  Map<int, List<PlanItem>> _planItems = {};
  int? _selectedDayOnCard;
  List<PlanItem> _todayPlanItems = []; //今天的課表項目

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
    _loadAllData();
  }
  
  Future<void> _loadAllData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    if (mounted) {
      setState(() {
        _currentUser = user;
        // 預設今天 否則跳到下一個訓練日
       if (user?.trainingDays != null && user!.trainingDays!.isNotEmpty) {
           final todayWeekday = DateTime.now().weekday;
           final trainingDays = user.trainingDays!.split(',').map(int.parse).toList();
           if (trainingDays.contains(todayWeekday)) {
             _selectedDayOnCard = todayWeekday;
           } else if (trainingDays.isNotEmpty) {
             _selectedDayOnCard = trainingDays.first;
        }
        }
      });
    }
    
    await Future.wait([
      _loadWeightData(),
      _loadWorkoutData(),
      _loadAllPlanItems(), // 【新增】同時載入課表
    ]);
  }

  Future<void> _loadAllPlanItems() async {
    Map<int, List<PlanItem>> items = {};
    for (int i = 1; i <= 7; i++) {
      items[i] = await DatabaseHelper.instance.getPlanItemsForDay(i);
    }
      //檢查課表
    final todayWeekday = DateTime.now().weekday;
    final todayItems = items[todayWeekday] ?? [];

    if (mounted) {
      setState(() {
        _planItems = items;
        _todayPlanItems = todayItems;
      });
    }
  }
  
  Future<void> _loadWeightData() async {
    final weightLogs = await DatabaseHelper.instance.getWeightLogs();
    if (!mounted) return;
    if (weightLogs.isEmpty) {
      setState(() { _latestWeight = null; _weightChange = null; });
      return;
    }
    final latestWeight = weightLogs[0].weight;
    double? weightChange;
    if (weightLogs.length > 1) {
      final previousWeight = weightLogs[1].weight;
      weightChange = latestWeight - previousWeight;
    }
    setState(() { _latestWeight = latestWeight; _weightChange = weightChange; });
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
          _loadAllData();
        },
      ),
    );
  }
//新增
void _startTodayWorkout() {
    final itemsForSelectedDay = _planItems[_selectedDayOnCard] ?? [];
    if (itemsForSelectedDay.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          // 限制高度，避免列表太長
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '請選擇要開始的動作',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: itemsForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final item = itemsForSelectedDay[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      title: Text(item.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.sets} 組 x ${item.weight} kg'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // 選擇後，關閉選單並跳轉
                        Navigator.pop(context);
                          final selectedItem = itemsForSelectedDay[index];
                          List<PlanItem> reorderedList = [selectedItem];
                          reorderedList.addAll(
                          itemsForSelectedDay.where((element) => element != selectedItem)
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrainingSessionPage(
                              planItems: reorderedList, // 傳入重新排序後的清單
                              bodyPart: BodyPart.chest, // 預設
                              initialIndex: 0, // 永遠從第一個開始
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWorkoutSummaryCard(),
            const SizedBox(height: 16),
            _buildWeightSummaryCard(),
            const SizedBox(height: 16),
            _buildMyPlansSection(),
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
          radius: 30,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本週訓練摘要', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$_workoutsThisWeek', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' 次', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              width: 80,
              child: sections.isEmpty
                  ? Center(child: Text('本週\n無紀錄', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)))
                  : PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 20,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummaryCard() {
    final changeValue = _weightChange;
    final changeColor = (changeValue == null || changeValue == 0) ? Colors.grey : (changeValue > 0 ? Colors.red.shade400 : Colors.green.shade400);
    final changeIcon = (changeValue == null || changeValue == 0) ? Icons.remove : (changeValue > 0 ? Icons.arrow_upward : Icons.arrow_downward);
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
                  _loadAllData();
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

  Widget _buildMyPlansSection() {
    final List<String> dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    List<int> trainingDays = [];
    
    if (_currentUser?.trainingDays != null && _currentUser!.trainingDays!.isNotEmpty) {
      trainingDays = _currentUser!.trainingDays!.split(',')
          .map((dayStr) => int.tryParse(dayStr) ?? 0)
          .where((dayInt) => dayInt >= 1 && dayInt <= 7)
          .toList()..sort();
    }

   final itemsForSelectedDay = _planItems[_selectedDayOnCard] ?? [];

  final isTodaySelected = _selectedDayOnCard == DateTime.now().weekday;
  final showStartButton = isTodaySelected && itemsForSelectedDay.isNotEmpty;
    return Card(
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlanEditorPage(account: widget.account)),
          );
          if (result == true) {
            _loadAllData();
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題和編輯按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('我的課表', style: Theme.of(context).textTheme.titleMedium),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 16),
              
              // 如果沒有設定練習日
              if (trainingDays.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('尚未設定練習日', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                )
              else
                // 如果已設定練習日
                Column(
                  children: [
                    // 1. 星期選擇器
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ToggleButtons(
                        isSelected: trainingDays.map((day) => day == _selectedDayOnCard).toList(),
                        onPressed: (int index) {
                          setState(() {
                            _selectedDayOnCard = trainingDays[index];
                          });
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 50.0),
                        children: trainingDays.map((day) => Text(dayNames[day - 1])).toList(),
                      ),
                    ),
                    const Divider(height: 24),
                    // 2. 課表內容
                    if (itemsForSelectedDay.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('這天沒有安排動作', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      Column(
                        children: itemsForSelectedDay.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.exerciseName, style: const TextStyle(fontSize: 16)),
                                Text('組數: ${item.sets}  重量: ${item.weight}kg', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  if (showStartButton) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startTodayWorkout,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('開始今日訓練'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // 用綠色凸顯
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
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