import SwiftUI

@main
struct DockSwichApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var isDockHidden = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dockの現在の状態を取得
        isDockHidden = getDockStatus()
        
        // ステータスバーアイテムを作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "Dock Switch")
            button.action = #selector(toggleDock)
            button.target = self
        }
        
        setupMenu()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Dockの表示・非表示を切り替え", action: #selector(toggleDock), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleDock() {
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
    
    func runShellCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
        } catch {
            print("Error running command: \(error)")
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
} 