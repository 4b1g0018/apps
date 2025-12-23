import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_log_model.dart';
import '../models/set_log_model.dart';
import '../models/exercise_model.dart';
import '../models/custom_exercise.dart';
import '../services/database_helper.dart';
import '../services/mock_data_service.dart';

// 用來暫存一筆訓練資料 (Exercise + Sets)
class TempWorkoutEntry {
  final BodyPart bodyPart;
  final Exercise exercise;
  final List<SetInput> sets;

  TempWorkoutEntry({
    required this.bodyPart,
    required this.exercise,
    required this.sets,
  });
}

class SetInput {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  SetInput({double? weight, int? reps}) {
    if (weight != null) weightController.text = weight.toString();
    if (reps != null) repsController.text = reps.toString();
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class ManualWorkoutLogPage extends StatefulWidget {
  final String account;

  const ManualWorkoutLogPage({super.key, required this.account});

  @override
  State<ManualWorkoutLogPage> createState() => _ManualWorkoutLogPageState();
}

class _ManualWorkoutLogPageState extends State<ManualWorkoutLogPage> {
  DateTime _selectedDate = DateTime.now();
  
  // 已加入的訓練列表
  final List<TempWorkoutEntry> _entries = [];
  bool _isLoading = false;

  @override
  void dispose() {
    for (var entry in _entries) {
      for (var s in entry.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // 不能選未來
      locale: const Locale('zh', 'TW'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // 開啟新增/編輯單一項目的頁面 (這裡用 BottomSheet 或 Dialog)
  void _openAddEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddEntrySheet(
        onConfirm: (entry) {
          setState(() {
            _entries.add(entry);
          });
        },
      ),
    );
  }

  Future<void> _saveAll() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少加入一項訓練')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (var entry in _entries) {
        // 1. 建立 WorkoutLog
        final workoutLog = WorkoutLog(
          exerciseName: entry.exercise.name,
          totalSets: entry.sets.length,
          completedAt: _selectedDate, 
          bodyPart: entry.bodyPart,
          account: widget.account,
          calories: 0,
          avgHeartRate: 0,
          maxHeartRate: 0,
        );

        final workoutLogId = await DatabaseHelper.instance.insertWorkoutLog(workoutLog);

        // 2. 建立 SetLogs
        for (int i = 0; i < entry.sets.length; i++) {
          final setInput = entry.sets[i];
          final setLog = SetLog(
            workoutLogId: workoutLogId,
            setNumber: i + 1,
            weight: double.tryParse(setInput.weightController.text) ?? 0,
            reps: int.tryParse(setInput.repsController.text) ?? 0,
          );
          await DatabaseHelper.instance.insertSetLog(setLog);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紀錄已儲存')));
        Navigator.pop(context, true); // 回傳 true 表示有更新
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入訓練紀錄'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 1. 日期選擇 (最上方)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  title: const Text('日期', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                  onTap: _selectDate,
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              // 2. 已加入的列表
              Expanded(
                child: _entries.isEmpty
                  ? Center(
                      child: Text('尚未加入任何動作\n點擊下方按鈕開始', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      )
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          // Card color handled by theme (0xFF2C2C2E)
                          child: ExpansionTile(
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: Text(entry.bodyPart.displayName.substring(0, 1), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(entry.exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${entry.sets.length} 組'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  // Dispose controllers
                                  for (var s in entry.sets) s.dispose();
                                  _entries.removeAt(index);
                                });
                              },
                            ),
                            children: entry.sets.map((s) => ListTile(
                              dense: true,
                              title: Text('${s.weightController.text} kg x ${s.repsController.text} 次'),
                              leading: const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                            )).toList(),
                          ),
                        );
                      },
                    ),
              ),
              
              // 3. 底部按鈕區
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openAddEntryForm,
                      icon: const Icon(Icons.add),
                      label: const Text('新增動作'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade700),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveAll,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade800, // 深藍色
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('儲存全部紀錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

// ------ 新增動作的表單 (BottomSheet) ------
class _AddEntrySheet extends StatefulWidget {
  final Function(TempWorkoutEntry) onConfirm;

  const _AddEntrySheet({required this.onConfirm});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  BodyPart _selectedBodyPart = BodyPart.values.first;
  List<Exercise> _availableExercises = [];
  Exercise? _selectedExercise;
  final List<SetInput> _sets = [];

  @override
  void initState() {
    super.initState();
    _addSet();
    _loadExercises();
  }

  void _addSet() {
    setState(() => _sets.add(SetInput()));
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() => _sets.removeAt(index));
    }
  }

  Future<void> _loadExercises() async {
    final predefined = MockDataService.getExercisesForBodyPart(_selectedBodyPart);
    final custom = await DatabaseHelper.instance.getCustomExercisesForBodyPart(_selectedBodyPart);
    final customAsExercise = custom.map((c) => Exercise(name: c.name, description: c.description)).toList();
    
    setState(() {
      _availableExercises = [...predefined, ...customAsExercise];
      if (_availableExercises.isNotEmpty) {
         _selectedExercise = _availableExercises.first;
      } else {
        _selectedExercise = null;
      }
    });
  }

  void _handleConfirm() {
    if (_selectedExercise == null) return;
    
    // Validate
    final validSets = _sets.where((s) => s.weightController.text.isNotEmpty && s.repsController.text.isNotEmpty).toList();
    
    if (validSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少輸入一組完整數據')));
      return;
    }

    // 建立 TempEntry
    final entry = TempWorkoutEntry(
      bodyPart: _selectedBodyPart,
      exercise: _selectedExercise!,
      sets: validSets, 
    );
    
    widget.onConfirm(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 讓 BottomSheet 長高一點
    return Container(
      padding: EdgeInsets.only(
        top: 16, left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Dark background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('新增動作', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BodyPart>(
                  value: _selectedBodyPart,
                  dropdownColor: Theme.of(context).cardColor,
                  decoration: const InputDecoration(labelText: '部位', border: OutlineInputBorder()),
                  items: BodyPart.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBodyPart = val);
                      _loadExercises();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<Exercise>(
                  value: _selectedExercise,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  decoration: const InputDecoration(labelText: '動作', border: OutlineInputBorder()),
                  items: _availableExercises.map((e) => DropdownMenuItem(value: e, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedExercise = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _sets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => Row(
                children: [
                   CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade800,
                    child: Text('${index+1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sets[index].weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '重量(kg)', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sets[index].repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '次數', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => _removeSet(index),
                  ),
                ],
              ),
            ),
          ),
          
          TextButton.icon(
             onPressed: _addSet, 
             icon: const Icon(Icons.add, color: Colors.blueAccent), 
             label: const Text('新增一組', style: TextStyle(color: Colors.blueAccent))
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade800, // 深藍色
            ),
            child: const Text('加入列表'),
          ),
        ],
      ),
    );
  }
}
