// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 【移除】不再需要 firebase_storage

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> syncUserData({String? nickname, String? hometown}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      if (nickname != null) 'nickname': nickname,
      if (hometown != null) 'hometown': hometown,
      'last_active': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid;
  }

  // 【修改】直接接收圖片字串 (Base64)
  Future<void> addPost({required String title, required String content, String? imageBase64}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String authorName = user.email!.split('@')[0];
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      if (data.containsKey('nickname') && data['nickname'].toString().isNotEmpty) {
        authorName = data['nickname'];
      }
    }

    await _db.collection('posts').add({
      'authorId': user.uid,
      'authorName': authorName,
      'title': title,
      'content': content,
      // 【修改】這裡存的是 Base64 字串，不是網址
      'imageUrl': imageBase64 ?? '', 
      'timestamp': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
    });
  }

 Stream<QuerySnapshot> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 5. 取得特定使用者的貼文 (個人檔案)
  Stream<QuerySnapshot> getUserPostsStream(String uid) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        // 注意：如果加上 orderBy 需要在 Firestore 建立索引，暫時先不加
        .snapshots();
  }
}


