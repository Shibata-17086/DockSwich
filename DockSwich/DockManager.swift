import Foundation
import Combine

class DockManager: ObservableObject {
    static let shared = DockManager()
    
    @Published var isDockHidden: Bool = false
    
    private init() {
        // 初期化時にDockの状態を取得
        isDockHidden = getDockStatus()
    }
    
    func toggleDock() {
        isDockHidden.toggle()
        
        if isDockHidden {
            // Dockを完全に非表示にする
            runShellCommand("defaults write com.apple.dock autohide -bool true && defaults write com.apple.dock autohide-delay -float 1000 && defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock")
        } else {
            // Dockを通常表示に戻す
            runShellCommand("defaults write com.apple.dock autohide -bool false && defaults delete com.apple.dock autohide-delay && defaults delete com.apple.dock no-bouncing && killall Dock")
        }
    }
    
    func getDockStatus() -> Bool {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.dock", "autohide-delay"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                // autohide-delayが1000以上ならDockは実質的に非表示と判断
                if let delay = Float(output), delay >= 1000 {
                    return true
                }
            }
        } catch {
            // autohide-delayが設定されていない場合はエラーになるので、
            // 次にautohideの状態を確認する
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
                print("Error getting Dock autohide status: \(error)")
            }
        }
        
        return false
    }
    
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