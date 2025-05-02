import SwiftUI

@main
struct DockSwichApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 500)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        // メインウィンドウを表示するメニュー項目
        menu.addItem(NSMenuItem(title: "メインウィンドウを表示", action: #selector(showMainWindow), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleDock() {
        DockManager.shared.toggleDock()
    }
    
    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
} 