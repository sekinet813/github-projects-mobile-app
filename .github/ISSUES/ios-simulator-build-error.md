# iOSシミュレーターでビルドエラーが発生する

## 問題の概要

iOSシミュレーター（iPhone 16）でアプリを実行しようとすると、Xcodeビルドエラーが発生します。

## エラーメッセージ

```
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
            { id:9D04A9C8-E286-434C-B5B4-0408BB6A36A1 }

    Available destinations for the "Runner" scheme:
            { platform:macOS, arch:arm64, variant:Designed for [iPad,iPhone], id:00008122-001C58CC2629001C, name:My Mac }
            { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
```

## 再現手順

1. `flutter clean` を実行
2. `flutter pub get` を実行
3. `flutter run` を実行
4. デバイス選択で `[2]: iPhone 16` を選択
5. エラーが発生

## 想定される原因

1. **シミュレーターが実際には起動していない**
   - Flutterがシミュレーターを検出しているが、Xcodeが認識していない状態
   - シミュレーターの状態が不正（クラッシュした、または不完全な状態）

2. **シミュレーターが削除された、または無効化された**
   - シミュレーターが削除されたが、Flutterのキャッシュに残っている
   - Xcodeの設定からシミュレーターが削除された

3. **Xcodeの設定に問題がある**
   - Xcodeのシミュレーター管理に問題がある
   - シミュレーターのランタイムが正しくインストールされていない

4. **FlutterとXcodeの間の同期の問題**
   - Flutterが検出したデバイスIDとXcodeが認識しているデバイスIDが一致しない

## 環境情報

- **OS**: macOS 15.7.1 (darwin-arm64)
- **Flutter**: 最新のstable channel
- **Xcode**: 利用可能（バージョン未確認）
- **シミュレーター**: iPhone 16 (ID: 9D04A9C8-E286-434C-B5B4-0408BB6A36A1)

## 試行した解決策

- `flutter clean` を実行済み
- `flutter pub get` を実行済み

## 推奨される解決策

### 1. シミュレーターの状態を確認

```bash
# 利用可能なシミュレーターを確認
xcrun simctl list devices

# 特定のシミュレーターの状態を確認
xcrun simctl list devices | grep "9D04A9C8-E286-434C-B5B4-0408BB6A36A1"
```

### 2. シミュレーターを起動

```bash
# シミュレーターを起動
open -a Simulator

# または、特定のシミュレーターを起動
xcrun simctl boot "9D04A9C8-E286-434C-B5B4-0408BB6A36A1"
```

### 3. シミュレーターを再作成

```bash
# 利用可能なデバイスタイプを確認
xcrun simctl list devicetypes

# 利用可能なランタイムを確認
xcrun simctl list runtimes

# 新しいシミュレーターを作成
xcrun simctl create "iPhone 16" "iPhone 16" "iOS-18-2"
```

### 4. Flutterのデバイスキャッシュをクリア

```bash
# Flutterのデバイスリストを更新
flutter devices

# 必要に応じて、Flutterのキャッシュをクリア
flutter clean
rm -rf ~/.flutter-devtools
```

### 5. Xcodeの設定を確認

- Xcodeを開いて、`Window > Devices and Simulators` でシミュレーターの状態を確認
- シミュレーターが表示されない場合は、再インストールを検討

### 6. 代替案：別のシミュレーターを使用

```bash
# 利用可能なシミュレーターを確認
flutter devices

# 別のシミュレーターを選択して実行
flutter run -d <device-id>
```

## 関連情報

- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos#ios-setup)
- [Xcode Simulator Documentation](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device)

## 優先度

**中** - iOS開発に影響があるが、AndroidやmacOSでは動作する

## ラベル

- `bug`
- `ios`
- `simulator`
- `build-error`

