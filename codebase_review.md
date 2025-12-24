# 專案程式碼複習指南 (Codebase Review Guide)

這份文件詳細列出了專案中 `Models`、`Services` 與 `Pages` 目錄下的**所有檔案**及其功能說明。

---

## 1. 資料模型 (Models) - 共 7 個檔案
位於 `lib/models/`，負責定義資料結構。

| 檔案名稱 | 功能說明 (Description) | 關鍵欄位/方法 |
| :--- | :--- | :--- |
| **`user_model.dart`** | **使用者模型**<br>定義使用者的基本資料與設定。 | `isPublic`: 公開/不公開<br>`fromMap()`: 這裡處理了資料型別轉換的邏輯 |
| **`workout_log_model.dart`** | **訓練紀錄主檔**<br>代表一次完整的運動紀錄 (例如：今天練胸)。 | `completedAt`: 完成時間<br>`bodyPart`: 訓練部位 (Enum) |
| **`set_log_model.dart`** | **組數明細檔**<br>代表訓練中的「每一組」數據。 | `weight`: 重量 (kg)<br>`reps`: 次數 |
| **`plan_item_model.dart`** | **課表項目**<br>定義每週計畫中某一天的訓練內容。 | `dayOfWeek`: 星期幾 (1-7)<br>`isRestDay`: 是否休息日 |
| **`weight_log_model.dart`** | **體重紀錄**<br>用於追蹤使用者的體重變化。 | `weight`: 體重數值<br>`createdAt`: 測量日期 |
| **`exercise_model.dart`** | **內建動作**<br>系統預設的訓練動作資料 (Hard-coded)。 | `imagePath`: 動作示範圖路徑<br>`BodyPart`: 部位列舉 |
| **`custom_exercise.dart`** | **自定義動作**<br>使用者自行新增的客製化動作。 | `id`: 資料庫主鍵<br>此模型允許使用者擴充動作庫而不受限於內建列表。 |

---

## 2. 核心服務 (Services) - 共 6 個檔案
位於 `lib/services/`，負責商業邏輯與資料存取。

| 檔案名稱 | 功能說明 (Description) | 技術亮點 |
| :--- | :--- | :--- |
| **`firestore_service.dart`** | **雲端資料庫服務**<br>處理 Firebase Firestore 的所有 CRUD 操作。 | **Singleton**: 單例模式確保連線唯一<br>**Batch**: 批次寫入優化效能 |
| **`database_helper.dart`** | **本地資料庫服務**<br>處理 SQLite 的所有操作 (離線存取用)。 | **sqflite**: 封裝了 SQL 語法<br>負責將資料保存在手機端 |
| **`auth_service.dart`** | **身分驗證服務**<br>處理登入、註冊、登出與訪客模式。 | **Firebase Auth**: 整合 Google 驗證<br>**Anonymous**: 訪客匿名登入機制 |
| **`pose_detector_service.dart`** | **AI 姿勢辨識服務**<br>處理相機串流影像，計算骨架與計數。 | **Google ML Kit**: 整合 AI 模型<br>**Vector Math**: 向量角度計算邏輯 |
| **`mock_data_service.dart`** | **模擬數據生成服務**<br>為訪客模式快速生成假的歷史紀錄。 | 用於 Demo 展示，讓新用戶能看到豐富的圖表數據。 |
| **`health_service.dart`** | **健康數據服務**<br>整合 Apple Health (HealthKit) 讀取數據。 | 負責權限請求與讀取步數、熱量等生理數據。 |

---

## 3. 頁面視圖 (Pages) - 共 21 個檔案
位於 `lib/pages/`，負責所有畫面呈現。

### A. 登入與導航
| 檔案名稱 | 功能說明 |
| :--- | :--- |
| **`login_page.dart`** | **登入/註冊頁**：App 的入口，包含表單驗證與訪客登入按鈕。 |
| **`main_menu_page.dart`** | **底部導航欄 (Main Shell)**：負責切換首頁、訓練、社群等分頁的容器。 |

### B. 首頁與儀表板
| 檔案名稱 | 功能說明 |
| :--- | :--- |
| **`dashboard_home_page.dart`** | **首頁儀表板**：顯示今日計畫、本週摘要與快速開始按鈕。 |
| **`weight_trend_page.dart`** | **體重趨勢圖**：繪製體重變化的折線圖，提供數據可視化。 |
| **`workout_history_page.dart`** | **訓練歷史紀錄**：依照日期列出過去的所有訓練項目。 |
| **`training_summary_page.dart`** | **本週訓練摘要**：統計本週的訓練頻率、部位分佈等數據。 |
| **`profile_page.dart`** | **個人檔案**：顯示個人基本資料 (非社群版)，可編輯身高體重。 |
| **`settings_page.dart`** | **設定頁面**：包含雲端備份、還原、切換深色模式與登出功能。 |

### C. 訓練流程 (核心功能)
| 檔案名稱 | 功能說明 |
| :--- | :--- |
| **`training_mode_selection_page.dart`** | **模式選擇**：選擇「AI 計數模式」或「手動紀錄模式」。 |
| **`select_part_page.dart`** | **選擇部位**：訓練第一步，選擇要練胸、背或腿。 |
| **`select_exercise_page.dart`** | **選擇動作**：訓練第二步，選擇具體的動作 (如伏地挺身)。 |
| **`exercise_setup_page.dart`** | **動作設定**：(AI模式前) 確認動作教學與相機架設引導。 |
| **`training_session_page.dart`** | **AI 訓練進行中**：開啟相機，即時顯示骨架與計數回饋。 |
| **`manual_workout_log_page.dart`** | **手動紀錄頁**：不開相機，直接手動輸入重量與次數。 |
| **`plan_editor_page.dart`** | **課表編輯器**：讓使用者安排每週哪幾天要練什麼部位。 |

### D. 社群與互動
| 檔案名稱 | 功能說明 |
| :--- | :--- |
| **`community_profile_page.dart`** | **社群個人主頁**：顯示大頭貼、貼文牆 (含公開/不公開邏輯)。 |
| **`create_post_page.dart`** | **發文頁面**：撰寫貼文內容並上傳圖片 (Base64)。 |
| **`friend_search_page.dart`** | **搜尋好友**：輸入 Email 或暱稱搜尋其他使用者。 |
| **`post_detail_page.dart`** | **貼文詳情**：點擊貼文後進入的詳細閱讀頁面。 |

### E. 其他功能
| 檔案名稱 | 功能說明 |
| :--- | :--- |
| **`video_analysis_page.dart`** | **影片分析**：(進階功能) 上傳影片進行 AI 動作分析。 |
| **`device_connection_page.dart`** | **裝置連線**：(預留功能) 用於連接藍牙心率帶或其他硬體。 |

---

## 4. 關鍵語法複習 (Syntax Review)

### 1. 單例模式 (Singleton Pattern)
**用途**：確保全域只有一個實例。
```dart
class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal(); 
}
```

### 2. 非同步處理 (Async/Await)
**用途**：避免卡住 UI，等待長時間操作。
```dart
Future<void> loadData() async {
  final data = await DatabaseHelper.instance.getAll();
  setState(() => _data = data);
}
```

### 3. 工廠建構子 (Factory Constructor)
**用途**：將 JSON 轉為物件。
```dart
factory User.fromMap(Map<String, dynamic> map) {
  return User(
    account: map['account'],
    isPublic: map['isPublic'] == 1, 
  );
}
```
