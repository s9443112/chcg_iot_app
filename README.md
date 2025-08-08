# AgriTalk IoT App

AgriTalk IoT App 是一個以 Flutter 開發的跨平台行動應用程式，提供農業物聯網裝置的即時監測、遠端控制與通知推送功能。  
本專案支援 **Android** 與 **iOS**，並整合 **Firebase Cloud Messaging (FCM)** 推播服務與 **Google Maps**。

---

## 📌 功能特色

- 📡 **即時資料顯示**：即時顯示感測器與控制器狀態。
- 🗺 **地圖定位**：使用 Google Maps 顯示裝置位置。
- 🔔 **推播通知**：整合 Firebase Messaging 支援主題訂閱與背景訊息。
- 📷 **影像與監控**：支援裝置攝影串流顯示。
- ⚙ **裝置控制**：支援開關、排程與環境條件控制。

---

## 🛠 環境需求

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x+
- Dart 3.x+
- Android Studio / VS Code / Xcode（iOS 開發）
- Android SDK / iOS SDK
- CocoaPods (iOS)
- Firebase 專案與設定檔 (`google-services.json` / `GoogleService-Info.plist`)

---

## 📥 專案安裝

```bash
# 1. 安裝套件
flutter pub get

# 2. 執行
flutter run 

# 編譯成apk檔案(至\build\app\outputs\flutter-apk\app-release.apk)
flutter build apk 


# IOS專區 編譯至ios手機內 (要注意IOS相關權限, 可上網查詢相關資料)
rm -rf Podfile.lock Pods .symlinks
pod cache clean --all
flutter clean
flutter pub get
cd ios
pod install
cd .. 
flutter run 

# 編譯成ios檔案
flutter build ios
```

## TODO

- ios firebase 需使用apple deveopler account (年費收費)
- ios apple store 上架需使用apple deveopler account (年費收費)

