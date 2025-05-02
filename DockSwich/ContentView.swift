import SwiftUI
import ServiceManagement

struct ContentView: View {
    // ローカルの状態変数のみ使用
    @State private var isDockHidden = false
    @State private var isLoginEnabled = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dock.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("DockSwich")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("macOSのDock有無を切り替えます")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("現在の状態:")
                    .font(.headline)
                
                HStack {
                    Text(isDockHidden ? "Dock: 非表示" : "Dock: 表示中")
                        .font(.title2)
                    
                    Spacer()
                    
                    Image(systemName: isDockHidden ? "eye.slash" : "eye")
                        .foregroundColor(isDockHidden ? .red : .green)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Button(action: {
                toggleDock()
            }) {
                Text(isDockHidden ? "Dockを表示する" : "Dockを非表示にする")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isDockHidden ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            // システム設定セクション
            VStack(alignment: .leading, spacing: 15) {
                Text("システム設定:")
                    .font(.headline)
                
                // ログイン時の自動起動設定
                Button(action: {
                    toggleLoginItem()
                }) {
                    HStack {
                        Image(systemName: isLoginEnabled ? "checkmark.square" : "square")
                        Text("ログイン時に自動的に起動")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Dock表示設定の保存
                Button(action: {
                    toggleDockSetting()
                }) {
                    HStack {
                        Image(systemName: isDockHidden ? "checkmark.square" : "square")
                        Text("現在のDock設定をシステム起動時に適用")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Text("メニューバーアイコンからも操作できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 500, height: 800)
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
    
    // Dock設定の切り替え
    private func toggleDockSetting() {
        isDockHidden.toggle()
        
        // トグル後の状態が現在のDock状態と異なる場合は適用
        let currentState = getCurrentDockHiddenState()
        if isDockHidden != currentState {
            toggleDock()
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
