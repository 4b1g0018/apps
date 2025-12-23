# 12/23 開發日誌

## 1. 訓練紀錄功能優化 (Training Log Refinement)

### 手動補登介面 (Manual Log)
*   **多動作儲存**：優化手動新增邏輯，支援同時儲存多個動作與組數。

### 訓練日曆顯示 (Workout History)
*   **解決組數顯示 Bug**：修復組數大於 10 時只顯示 "1" 的問題（文字溢出）。
*   **新增詳細數據顯示**：在列表項目中直接顯示每一組的 `重量 x 次數` (e.g., "60kg x 12")。
*   **日曆標記優化 (Calendar Marker)**：
    *   廢除原本的「點點」標記，改用 **「彩色光環 (Gradient Ring)」** 圍繞日期數字。
    *   **技術實作**：使用 `CustomPainter` 與 `SweepGradient`，當單日有多個訓練部位時，光環會呈現多色漸層，解決了點點重疊與排列不整齊的問題。

## 2. 熱量顯示邏輯 (Calorie Display Logic)
*   **條件式顯示**：
    *   修改 `WorkoutHistoryPage`，現在只有當 `totalCalories > 0` 時才會顯示「今日消耗熱量」區塊。
    *   這確保了只有在使用 Apple Watch (提供心率數據) 進行訓練時才顯示熱量，手動補登的紀錄則自動隱藏該區塊，符合使用者「有連結裝置才算熱量」的需求。

## 3. 專案建置與發布 (Build & Deploy)
*   **Android APK 建置嘗試**：
    *   嘗試執行 `flutter build apk --release`。
    *   遭遇 **Gradle 8.12** 與 **AGP 8.9.1** (Alpha/Beta levels) 的相容性問題，導致獨立 APK 建置失敗。
    *   **決策**：為了不影響現有 `flutter run` 的開發穩定性，決定回退所有 Gradle 版本更動，保持開發環境正常運作。確認 iOS/Android 連接手機除錯功能皆正常。
