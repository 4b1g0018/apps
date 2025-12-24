# 專案程式碼複習指南 (Codebase Review Guide)

## 1. 專案結構總覽 (Project Structure)
本專案採用經典的 **MVC (Model-View-Controller)** 分層架構變體：

*   **Models (`lib/models/`)**：**資料模型層**。
    *   負責定義資料的結構與型態。
    *   負責 JSON/Map 與物件之間的轉換。
*   **Services (`lib/services/`)**：**服務層 (Controller)**。
    *   負責商業邏輯、資料庫存取、API 呼叫。
*   **Pages (`lib/pages/`)**：**視圖層 (View)**。
    *   負責 UI 畫面的呈現與使用者互動。

---

## 2. 核心檔案導讀 (Key Files)

### A. Models (資料模型)

| 檔案名稱 (`lib/models/`) | 用途 (Purpose) | 關鍵特性 (Key Features) |
| :--- | :--- | :--- |
| **`user_model.dart`** | 定義使用者資料結構 | `factory fromMap()`: JSON 轉物件<br>`isPublic`: 隱私設定欄位 |
| **`workout_log_model.dart`** | 訓練紀錄模型 | `toIso8601String()`: 時間格式化<br>`bodyPart`: 關聯列舉 (Enum) |
| **`plan_item_model.dart`** | 課表項目模型 | 封裝每週訓練排程 (Week Plan) |
| **`set_log_model.dart`** | 組數模型 | 定義每一組的重量與次數 (Weight/Reps) |

### B. Services (服務層)

| 檔案名稱 (`lib/services/`) | 用途 (Purpose) | 語法亮點 (Syntax Highlights) |
| :--- | :--- | :--- |
| **`firestore_service.dart`** | 雲端資料庫操作 | **`Singleton`**: 單例模式<br>**`Stream`**: 即時數據串流<br>**`Batch`**: 批次寫入 |
| **`auth_service.dart`** | 身分驗證管理 | **`Firebase Auth`**: 整合 Google 登入<br>**`Anonymous`**: 訪客匿名登入 |
| **`database_helper.dart`** | 本地資料庫 (SQLite) | **`sqflite`**: 本地 SQL 操作<br>**`CRUD`**: 增刪改查封裝 |
| **`pose_detector_service.dart`**| AI 姿勢運算 | **`Google ML Kit`**: 整合 AI 模型<br>**`Vector Math`**: 向量角度計算 |

### C. Pages (視圖層)

| 檔案名稱 (`lib/pages/`) | 用途 (Purpose) | UI 元件 (Components) |
| :--- | :--- | :--- |
| **`training_session_page.dart`** | AI 訓練主畫面 | **`Stack`**: 疊加相機與繪圖層<br>**`CustomPainter`**: 繪製骨架線條 |
| **`login_page.dart`** | 登入與註冊 | **`Form`**: 表單驗證<br>**`TextFormField`**: 輸入框邏輯 |
| **`dashboard_home_page.dart`** | 首頁儀表板 | **`FutureBuilder`**: 非同步資料載入<br>**`ListView`**: 列表渲染 |
| **`community_profile_page.dart`**| 社群個人檔案 | **`StreamBuilder`**: 監聽貼文更新<br>**`Base64`**: 圖片解碼顯示 |

---

## 3. 關鍵語法複習 (Syntax Review)

### 1. 單例模式 (Singleton Pattern)
**用途**：確保全域只有一個資料庫連線實例，避免重複連線浪費資源。
```dart
class FirestoreService {
  // 1. 定義靜態私有實例 (唯一的)
  static final FirestoreService instance = FirestoreService._internal();
  
  // 2. 私有建構子，防止外部直接 new FirestoreService()
  FirestoreService._internal(); 
}

// 呼叫方式：
FirestoreService.instance.searchUsers(...);
```

### 2. 非同步處理 (Async/Await)
**用途**：避免資料庫讀取或網路請求卡住 UI，使用 `async/wait` 等待結果。
```dart
// Future<User?>: 代表這個函式「未來」會回傳一個 User 物件 (或 null)
Future<User?> getUserByAccount(String account) async {
  // await: 暫停函式執行，直到資料庫查詢完成
  final maps = await _db.query(...);
  
  if (maps.isEmpty) return null;
  return User.fromMap(maps.first);
}
```

### 3. 串流監聽 (Stream & StreamBuilder)
**用途**：當後端資料改變（如有人按讚、發新文）時，App 畫面會自動刷新。
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirestoreService.instance.getPostsStream(), // 1. 監聽這個資料源
  builder: (context, snapshot) {
    // 2. 判斷資料狀態
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator(); // 載入中轉圈圈
    }
    
    // 3. 有資料，自動渲染 ListView
    final docs = snapshot.data?.docs ?? [];
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) => PostCard(data: docs[index]),
    ); 
  },
)
```

### 4. 工廠建構子 (Factory Constructor)
**用途**：用於將資料庫回傳的 Map (JSON格式) 轉換為 Dart 物件，並處理錯誤數據。
```dart
class User {
  // factory: 不一定要建立新實例，可以回傳快取或處理邏輯
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      account: map['account'],
      // 處理資料型別轉換 (如 int 轉 bool)
      isPublic: (map['isPublic'] is int) ? (map['isPublic'] == 1) : true, 
      photoUrl: map['photoUrl'],
    );
  }
}
```

---

## 4. 資料庫架構筆記 (Database Schema)

### 本地 (SQLite)
*   User table: 存帳號密碼、身體數據。
*   WorkoutLog table: 存訓練日期、動作名稱。
*   WeightLog table: 存體重變化。

### 雲端 (Firestore - NoSQL)
*   **Collection `users`**: 
    *   Document (uid): 存用戶基本資料。
        *   Sub-collection `workout_logs`: 備份訓練紀錄。
*   **Collection `posts`**: 
    *   Document (auto-id): 存貼文內容、`imageUrl` (Base64)。
*   **Collection `avatars`** (冷熱分離):
    *   Document (uid): 只存 `imageBase64` 大頭貼，優化讀取效能。
