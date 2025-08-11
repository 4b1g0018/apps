// lib/pages/recommendations_page.dart

import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../services/plan_service.dart';
import '../models/user_model.dart';
import '../models/workout_plan_model.dart';

class RecommendationsPage extends StatefulWidget {
  final String account;
  const RecommendationsPage({super.key, required this.account});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  // 使用 Future 來處理非同步讀取
  late Future<WorkoutPlan?> _recommendedPlanFuture;

  @override
  void initState() {
    super.initState();
    _recommendedPlanFuture = _loadRecommendedPlan();
  }

  Future<WorkoutPlan?> _loadRecommendedPlan() async {
    // 1. 取得使用者資料
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    if (user == null || user.fitnessLevel == null || user.fitnessLevel!.isEmpty) {
      return null; // 如果沒有設定等級，就不推薦
    }

    // 2. 取得所有預設計畫
    final allPlans = PlanService.getPredefinedPlans();

    // 3. 找出符合使用者等級的計畫
    final userLevel = FitnessLevel.values.firstWhere((e) => e.name == user.fitnessLevel);
    
    try {
      return allPlans.firstWhere((plan) => plan.targetLevel == userLevel);
    } catch (e) {
      return null; // 如果找不到對應的計畫
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('建議課程'),
      ),
      body: FutureBuilder<WorkoutPlan?>(
        future: _recommendedPlanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('載入建議時發生錯誤'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('目前沒有適合您的建議課程。\n請先到「設定」>「個人資料」確認已選擇健身強度。', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            );
          }
          
          final plan = snapshot.data!;

          // 如果計畫裡沒有任何一天的課表，也顯示提示
          if (plan.days.isEmpty) {
            return Center(
              child: Text('${plan.name}\n課表即將推出，敬請期待！', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(plan.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),
              // 用 ExpansionTile 來顯示每一天的課表
              ...plan.days.map((day) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(day.dayLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(day.focus),
                    children: day.exercises.map((exercise) {
                      return ListTile(
                        title: Text(exercise.name),
                        trailing: Text(exercise.sets, style: const TextStyle(color: Colors.grey)),
                        dense: true,
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}