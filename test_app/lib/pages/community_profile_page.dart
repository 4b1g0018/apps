// lib/pages/community_profile_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 導入 Firestore
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/firestore_service.dart'; // 導入 Firestore 服務

class CommunityProfilePage extends StatefulWidget {
  final String account;
  const CommunityProfilePage({super.key, required this.account});

  @override
  State<CommunityProfilePage> createState() => _CommunityProfilePageState();
}

class _CommunityProfilePageState extends State<CommunityProfilePage> {
  User? _currentUser;
  // 我們需要用戶的 UID 來查詢貼文，這可以從 Firebase Auth 獲得，
  // 或者如果我們假設 account 唯一對應一個 uid，我們可以先查完 SQLite 再去查 Firestore。
  // 為了簡化，我們先假設登入的使用者就是查看自己檔案的使用者。
  // 如果是查看別人的檔案，我們需要先從 Firestore 用 email 查到 uid (這部分比較複雜，先略過)。
  
  // 暫時解法：直接使用 AuthService 裡的 currentUser 來查詢「自己的」貼文
  // 如果要查看別人，需要傳入 targetUid
  // 這裡我們先做「查看自己」的功能

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

  // 編輯暱稱
  Future<void> _editProfile() async {
    if (_currentUser == null) return;
    final nicknameController = TextEditingController(text: _currentUser!.nickname ?? '');
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('編輯個人資料', style: TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: nicknameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: '暱稱', labelStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(dialogContext)),
          TextButton(
            child: const Text('儲存'),
            onPressed: () async {
              if (_currentUser != null) {
                final newNickname = nicknameController.text;
                final updatedUser = _currentUser!.copyWith(nickname: newNickname);
                
                // 同步更新本地和雲端
                await DatabaseHelper.instance.updateUser(updatedUser);
                await FirestoreService.instance.syncUserData(nickname: newNickname);
                
                _loadUserData();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
          ),
        ],
      ),
    );
  }

  // 編輯家鄉
  Future<void> _editHometown() async {
    if (_currentUser == null) return;
    final hometownController = TextEditingController(text: _currentUser!.hometown ?? '');
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('設定家鄉', style: TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: hometownController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: '家鄉', labelStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(dialogContext)),
          TextButton(
            child: const Text('儲存'),
            onPressed: () async {
              if (_currentUser != null) {
                final newHometown = hometownController.text;
                final updatedUser = _currentUser!.copyWith(hometown: newHometown);
                
                await DatabaseHelper.instance.updateUser(updatedUser);
                await FirestoreService.instance.syncUserData(hometown: newHometown);

                _loadUserData();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
          ),
        ],
      ),
    );
  }

  // 【核心新增】建立真實的雲端週歷史列表
  Widget _buildRealWeekHistory() {
    // 取得當前登入使用者的 UID (透過 AuthService 或是 FirestoreService 已經實例化的 auth)
    // 這裡我們直接用 FirestoreService 裡的 auth 實體比較方便，但它是私有的。
    // 所以我們用 FirebaseAuth.instance
    final currentUid = FirestoreService.instance.getCurrentUserUid(); 
    // 注意：這需要您在 FirestoreService 補一個 getter，或者直接 import firebase_auth

    if (currentUid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.getUserPostsStream(currentUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('載入錯誤');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('尚未上傳任何貼文', style: TextStyle(color: Colors.grey))),
          );
        }

        // 1. 資料轉換與排序
        List<Map<String, dynamic>> posts = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        // 雖然 query 已經 filter 了，但保險起見可以在這裡做最後確認

        // 2. 分組邏輯 (依照週)
        Map<DateTime, List<Map<String, dynamic>>> groupedPosts = {};
        for (var post in posts) {
          final Timestamp? ts = post['timestamp'];
          if (ts == null) continue;
          final date = ts.toDate();
          // 取得該週週一
          final startOfWeek = DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
          
          if (!groupedPosts.containsKey(startOfWeek)) {
            groupedPosts[startOfWeek] = [];
          }
          groupedPosts[startOfWeek]!.add(post);
        }

        // 3. 建立 UI
        return Column(
          children: groupedPosts.entries.map((entry) {
            final startOfWeek = entry.key;
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final weekPosts = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 週標題
                  Row(
                    children: [
                      // 這裡可以算一下是今年的第幾週，或者直接顯示日期
                      Text('${DateFormat('M/d').format(startOfWeek)} - ${DateFormat('M/d').format(endOfWeek)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${weekPosts.length} 篇貼文', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 圖片列表
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: weekPosts.map((post) {
                      final imageBase64 = post['imageUrl'] as String?;
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: (imageBase64 != null && imageBase64.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(imageBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.error, color: Colors.white24),
                                ),
                              )
                            : const Center(child: Icon(Icons.text_fields, color: Colors.white24)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) { 
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    
    final userAccount = _currentUser!.account;
    final defaultNickname = userAccount.split('@').first;
    final displayName = _currentUser!.nickname != null && _currentUser!.nickname!.isNotEmpty 
                            ? _currentUser!.nickname! 
                            : defaultNickname; 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('個人檔案', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _editProfile,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('@$userAccount', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  ),
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle), child: const Icon(Icons.person, size: 50, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.white), const SizedBox(width: 8), const Text('發佈週數 : 5', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 8),
            GestureDetector(onTap: _editHometown, child: Row(children: [const Icon(Icons.info_outline, size: 16, color: Colors.white), const SizedBox(width: 8), Text(_currentUser?.hometown != null && _currentUser!.hometown!.isNotEmpty ? '家鄉 : ${_currentUser!.hometown}' : '家鄉 : +新增', style: TextStyle(color: Colors.grey.shade400, fontSize: 14))])),
            
            const SizedBox(height: 32),
            const Text('已上傳貼文歷史', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            
            // 【修改】這裡呼叫新的真實資料方法
            _buildRealWeekHistory(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}