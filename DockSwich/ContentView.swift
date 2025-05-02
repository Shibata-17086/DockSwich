import SwiftUI
import ServiceManagement
import AppKit

struct ShortcutKey: Equatable, Codable {
    var keyCode: UInt16
    var modifiersRaw: UInt
    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiersRaw) }
    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if let key = keyCodeToString(keyCode) { parts.append(key) }
        return parts.joined(separator: "+")
    }
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"; case 1: return "S"; case 2: return "D"; case 3: return "F"
        case 4: return "H"; case 5: return "G"; case 6: return "Z"; case 7: return "X"
        case 8: return "C"; case 9: return "V"; case 11: return "B"; case 12: return "Q"
        case 13: return "W"; case 14: return "E"; case 15: return "R"; case 17: return "T"
        case 31: return "O"; case 32: return "U"; case 34: return "I"; case 35: return "P"
        case 37: return "L"; case 38: return "J"; case 40: return "K"; case 45: return "N"
        case 46: return "M"; case 36: return "Return"; case 49: return "Space"
        default: return nil
        }
    }
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiersRaw = modifiers.rawValue
    }
}

struct ContentView: View {
    @State private var isDockHidden = false
    @State private var isLoginEnabled = false
    @State private var applyDockSettingOnLogin = UserDefaults.standard.bool(forKey: "applyDockSettingOnLogin")
    @State private var isRecordingShortcut = false
    @State private var shortcutKey: ShortcutKey? = UserDefaults.standard.data(forKey: "shortcutKey").flatMap { try? JSONDecoder().decode(ShortcutKey.self, from: $0) }
    @State private var showRestartAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Image(systemName: "dock.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            Text("DockSwich")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 2)
            Text("Dockの表示・非表示を切り替え")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            Divider()
                .padding(.bottom, 8)
            // Dock状態
            HStack {
                Label(isDockHidden ? "Dock: 非表示" : "Dock: 表示中",
                      systemImage: isDockHidden ? "eye.slash" : "eye")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            // Dock切り替えボタン
            Button(isDockHidden ? "Dockを表示する" : "Dockを非表示にする") {
                toggleDock()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom, 16)
            Divider()
            // 設定セクション
            Form {
                Section(header: Text("システム設定")) {
                    Toggle(isOn: $applyDockSettingOnLogin) {
                        Text("現在のDock設定をシステム起動時に適用")
                    }
                    .onChange(of: applyDockSettingOnLogin) { value in
                        UserDefaults.standard.set(value, forKey: "applyDockSettingOnLogin")
                    }
                    Toggle(isOn: $isLoginEnabled) {
                        Text("ログイン時に自動的に起動")
                    }
                    .onChange(of: isLoginEnabled) { _ in
                        toggleLoginItem()
                    }
                }
                Section(header: Text("ショートカットキー設定")) {
                    HStack {
                        Button(action: { isRecordingShortcut = true }) {
                            Text(isRecordingShortcut ? "キー入力待ち..." : "ショートカットを記録")
                        }
                        if let shortcut = shortcutKey {
                            Text("登録済み: " + shortcut.displayString)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                    }
                    if shortcutKey != nil {
                        Button("ショートカットをクリア") {
                            shortcutKey = nil
                            UserDefaults.standard.removeObject(forKey: "shortcutKey")
                            showRestartAlert = true
                        }
                        .font(.caption)
                    }
                }
            }
            .frame(maxWidth: 440)
            .padding(.top, 8)
            Spacer()
            Text("メニューバーアイコンからも操作できます")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
        }
        .frame(width: 360, height: 420)
        .background(ShortcutCaptureView(isRecording: $isRecordingShortcut, shortcutKey: Binding(get: { shortcutKey }, set: { newValue in
            shortcutKey = newValue
            if let key = newValue, let data = try? JSONEncoder().encode(key) {
                UserDefaults.standard.set(data, forKey: "shortcutKey")
                showRestartAlert = true
            }
        })))
        .alert(isPresented: $showRestartAlert) {
            Alert(
                title: Text("アプリの再起動が必要です"),
                message: Text("ショートカットキーの変更を反映するにはDockSwichを再起動してください。"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadInitialState()
        }
    }
    
    // 初期状態の読み込み
    private func loadInitialState() {
        // 現在のDock状態を取得
        isDockHidden = getCurrentDockHiddenState()
        
        // ログイン状態を取得（常にfalseとして初期化）
        isLoginEnabled = false
    }
    
    // 現在のDock表示状態を取得
    private func getCurrentDockHiddenState() -> Bool {
        // MacOSのデフォルト設定から読み取る
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.dock", "autohide-delay"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if let delay = Float(output), delay >= 1000 {
                    return true
                }
            }
        } catch {
            // autohide-delayが設定されていない場合はautohideの状態を確認
            let autohideTask = Process()
            let autohidePipe = Pipe()
            
            autohideTask.launchPath = "/usr/bin/defaults"
            autohideTask.arguments = ["read", "com.apple.dock", "autohide"]
            autohideTask.standardOutput = autohidePipe
            
            do {
                try autohideTask.run()
                let autohideData = autohidePipe.fileHandleForReading.readDataToEndOfFile()
                if let autohideOutput = String(data: autohideData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return autohideOutput == "1"
                }
            } catch {
                print("Dock status check error: \(error)")
            }
        }
        
        return false
    }
    
    // Dockの表示/非表示を切り替え
    private func toggleDock() {
        isDockHidden.toggle()
        
        if isDockHidden {
            // Dockを完全に非表示にする
            runShellCommand("defaults write com.apple.dock autohide -bool true && defaults write com.apple.dock autohide-delay -float 1000 && defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock")
        } else {
            // Dockを通常表示に戻す
            runShellCommand("defaults write com.apple.dock autohide -bool false && defaults delete com.apple.dock autohide-delay && defaults delete com.apple.dock no-bouncing && killall Dock")
        }
    }
    
    // ログイン項目設定の切り替え
    private func toggleLoginItem() {
        isLoginEnabled.toggle()
        
        // ログイン項目の設定を変更
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.DockSwich"
        if #available(macOS 13.0, *) {
            // macOS 13.0以降はSMAppServiceを使用
            do {
                if isLoginEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set login item: \(error)")
            }
        } else {
            // 古いバージョンではSMLoginItemSetEnabledを使用
            let success = SMLoginItemSetEnabled(bundleID as CFString, isLoginEnabled)
            if !success {
                print("Failed to set login item using SMLoginItemSetEnabled")
            }
        }
    }
    
    // シェルコマンドを実行
    private func runShellCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
        } catch {
            print("Error running command: \(error)")
        }
    }
}

// NSViewでキーイベントをキャプチャするためのラッパー
struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcutKey: ShortcutKey?
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyDown = { event in
            if isRecording {
                shortcutKey = ShortcutKey(keyCode: event.keyCode, modifiers: event.modifierFlags)
                isRecording = false
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)
    }
    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

