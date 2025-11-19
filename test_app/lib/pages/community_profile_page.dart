// lib/pages/community_profile_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class CommunityProfilePage extends StatefulWidget {
  final String account;
  const CommunityProfilePage({super.key, required this.account});

  @override
  State<CommunityProfilePage> createState() => _CommunityProfilePageState();
}

class _CommunityProfilePageState extends State<CommunityProfilePage> {
  User? _currentUser;
  
  // 模擬的貼文圖片 URL 列表
  final List<String> _mockPhotoUrls = [
    'https://via.placeholder.com/150/34C759/FFFFFF?text=P1',
    'https://via.placeholder.com/150/FF9500/FFFFFF?text=P2',
    'https://via.placeholder.com/150/5AC8FA/FFFFFF?text=P3',
    'https://via.placeholder.com/150/FF375F/FFFFFF?text=P4',
    'https://via.placeholder.com/150/5E5E5E/FFFFFF?text=P5',
    'https://via.placeholder.com/150/007AFF/FFFFFF?text=P6',
    'https://via.placeholder.com/150/A2845E/FFFFFF?text=P7',
    'https://via.placeholder.com/150/484848/FFFFFF?text=P8',
    'https://via.placeholder.com/150/C69C6D/FFFFFF?text=P9',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper.instance.getUserByAccount(widget.account);
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _editProfile() async {
    if (_currentUser == null) return;
    final nicknameController = TextEditingController(text: _currentUser!.nickname ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('編輯個人資料', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nicknameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '暱稱', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('儲存'),
            onPressed: () async {
              if (_currentUser != null) {
                final updatedUser = _currentUser!.copyWith(nickname: nicknameController.text);
                await DatabaseHelper.instance.updateUser(updatedUser);
                _loadUserData();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editHometown() async {
    if (_currentUser == null) return;
    final hometownController = TextEditingController(text: _currentUser!.hometown ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('設定家鄉', style: TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: hometownController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: '家鄉 (例如：台北市)', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
        ),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('儲存'),
            onPressed: () async {
              if (_currentUser != null) {
                final updatedUser = _currentUser!.copyWith(hometown: hometownController.text);
                await DatabaseHelper.instance.updateUser(updatedUser);
                _loadUserData();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHistory() {
    final List<Widget> weekSections = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 5; i++) {
      final startOfWeek = now.subtract(Duration(days: 7 * i)).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final weekNumber = 5 - i;
      
      weekSections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('第 ${weekNumber} 週', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('${DateFormat('M月d日').format(startOfWeek)} 至 ${DateFormat('M月d日').format(endOfWeek)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: List.generate(3, (index) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      _mockPhotoUrls[index], 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade800),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: weekSections);
  }


  @override
  Widget build(BuildContext context) {
    // 【核心修正】處理載入中的狀態
    if (_currentUser == null) { 
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 優先顯示暱稱，如果沒有則顯示帳號
    final displayName = _currentUser!.nickname != null && _currentUser!.nickname!.isNotEmpty 
                            ? _currentUser!.nickname! 
                            : (_currentUser!.account); // 此處 currentUser 已確定不為 null

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('個人檔案', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 頭像與名稱區塊 (可點擊編輯) ---
            GestureDetector(
              onTap: _editProfile,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${_currentUser!.account}', 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. 統計資訊 (發佈週數) ---
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text('發佈週數 : 2', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            
            // --- 家鄉設定 (可點擊編輯) ---
            GestureDetector(
              onTap: _editHometown,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _currentUser!.hometown != null && _currentUser!.hometown!.isNotEmpty
                        ? '家鄉 : ${_currentUser!.hometown}'
                        : '家鄉 : +新增',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // --- 3. 週紀錄歷史列表 ---
            const Text('已上傳貼文歷史', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            
            _buildWeekHistory(), // 呼叫歷史列表

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}