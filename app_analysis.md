# アプリケーション分析: DockSwich

## 概要
**DockSwich**は、macOSのDockを簡単に表示・非表示できるメニューバーアプリケーションです。

## アプリケーションの種類
- **プラットフォーム**: macOS専用アプリケーション
- **技術スタック**: SwiftUI + Swift
- **配布方法**: DMGインストーラー
- **開発ツール**: Xcode（.xcodeprojファイルあり）

## 主な機能
1. **Dock表示切り替え**: メニューバーからワンクリックでDockの表示・非表示を切り替え
2. **キーボードショートカット**: カスタマイズ可能なホットキーでDockをトグル
3. **自動起動設定**: ログイン時にアプリを自動起動する設定
4. **状態保存**: システム起動時に前回のDock設定を復元
5. **リアルタイム状態表示**: 現在のDockの状態をUIに表示

## 技術的特徴
- **UI**: SwiftUIを使用したAppleらしいシンプルなデザイン
- **設定保存**: UserDefaultsを使用
- **グローバルホットキー**: Carbon APIを利用
- **Dock制御**: シェルコマンド（`defaults`と`killall Dock`）を使用
- **システム要件**: macOS 11.0以降

## プロジェクト構造
```
DockSwich/
├── DockSwichApp.swift      # メインアプリケーション
├── ContentView.swift       # UI画面（11KB、283行）
├── DockManager.swift       # Dock制御ロジック
├── Assets.xcassets/        # アプリアイコンなどのリソース
└── Info.plist             # アプリケーション情報
```

## 開発背景
このアプリケーションはCursorとGPT4.1を使用して作られており、AIアシスタントを活用したmacOSアプリ開発の事例です。

## ライセンス
MITライセンスで配布されています。