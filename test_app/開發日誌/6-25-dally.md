# 專題開發日誌 - 2025/06/26

## 今日進度總結

今天完善 App 的使用者後台功能，成功地實作了**「詳細設定」**與**「個人資料修改」**這兩個重要的頁面。現在，使用者不僅能客製化 App 的提醒與聲音，還能隨時查看並更新自己的身高、體重等個人資料，讓整個 App 的使用者系統變得更加完整。

---

## 口語化的故事時間：我們今天做了什麼？

繼上次把訓練流程打通後，我們今天回來把主選單上剩下的按鈕，一個個點亮。

1.  **蓋了一間「設定室」**：我們首先建立了 `settings_page.dart`。這是一個很單純的房間，裡面放了幾個「提醒」和「音效」的開關，讓使用者可以客製化自己的 App 體驗。

2.  **打造了「個人VIP室」**：接著，我們開始蓋更重要的 `profile_page.dart`。這個房間的目標是，讓使用者進來後，可以看到自己當初註冊時填的身高、體重等資料，而且還可以修改它們。

3.  **訓練「資料庫服務生」新技能**：為了讓「個人VIP室」能正常運作，我們把「服務生」(`database_helper.dart`) 叫來，教了它兩項新技能：
    * **「認人」**：學會根據客人的「帳號」，準確地從廚房（資料庫）裡，找出這位客人的完整資料。
    * **「改訂單」**：學會當客人修改資料後，能把新的資料拿回廚房去更新。

4.  **建立「VIP通行證」**：最後，為了讓服務生知道該去服務哪位客人，我們設計了一張「VIP通行證」（也就是 `account` 這個參數）。當使用者登入成功時，`login_page` 就會發給 `main_menu_page` 這張通行證。之後，當使用者點擊「個人資料修改」時，`main_menu_page` 就會拿著這張通行證，去打開專屬於這位使用者的「個人VIP室」。

經過一番努力和除錯，我們成功地把所有環節都串連起來了！

---

## 專業的技術總結

### 1. 使用者資料 CRUD 功能完善

我們擴充了 `DatabaseHelper`，使其具備了更完整的 CRUD (Create, Read, Update, Delete) 功能。

* **Read (讀取)**: 新增了 `getUserByAccount(String account)` 方法。此方法利用 `WHERE` 條件句，從 `users` 資料表中精準地查詢特定帳號的使用者資料。
* **Update (更新)**: 新增了 `updateUser(User user)` 方法。此方法利用 `db.update`，並同樣搭配 `WHERE` 條件句，來更新特定 `id` 的使用者資料。

### 2. 資料模型化 (`User` Model)

* 為了讓使用者資料在程式碼中有一個標準、強型別的結構，我們建立了 `lib/models/user_model.dart`。
* `User` 類別中包含了 `toMap`、`fromMap` 和 `copyWith` 方法：
    * `toMap` / `fromMap`：負責在 Dart 物件與資料庫的 `Map` 格式之間進行轉換。
    * `copyWith`：這是一個非常實用且優雅的方法，它能讓我們在不直接修改原物件的情況下，建立一個只更新了部分欄位的新物件，非常適合用在「修改個人資料」這樣的情境。

### 3. 頁面間的狀態傳遞

* 我們實踐了從 `LoginPage` 登入成功後，將使用者 `account` 字串作為參數，傳遞給 `MainMenuPage` 的建構子。
* `MainMenuPage` 再將這個 `account` 參數，繼續傳遞給 `ProfilePage`，確保了資料頁面能準確地知道要為哪位使用者讀取和更新資料。

---

## 更新後的專案結構

我們今天為 App 的使用者系統，新增了兩個重要的頁面和一個資料模型。


lib/
├── main.dart             # App 總入口
|
├── models/               # 【藍圖/規格表】資料夾
│   ├── exercise_model.dart     # (舊)
│   ├── workout_log_model.dart  # (舊)
│   └── user_model.dart         # (新) 定義使用者的資料結構
|
├── pages/                # 【展示廳】資料夾 (所有 UI 頁面)
│   ├── ... (舊頁面)
│   ├── profile_page.dart       # (新) 「個人資料修改」的頁面
│   └── settings_page.dart      # (新) 「詳細設定」的頁面
|
└── services/             # 【後勤部門/工具箱】資料夾
└── database_helper.dart      # (有修改) 新增讀取與更新使用者的方法


---

## 下一步規劃

App 的軟體架構和核心功能已經非常完整了！我們幾乎已經把企劃書中所有「非硬體」的功能都蓋出了骨架。

接下來，我們就可以準備迎接專案中最核心、也最有趣的大魔王了：

**「開始實作藍牙連線的功能，用真實的感測器數據，來取代我們目前的假資料。」**

