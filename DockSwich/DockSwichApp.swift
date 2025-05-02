import SwiftUI

@main
struct DockSwichApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 起動時はウィンドウを表示しない
        // メニューから「メインウィンドウを表示」を選択したときのみContentViewを表示
        Settings {
            EmptyView()
        }
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
        // ContentViewのウィンドウを動的に生成して表示
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "DockSwich"
        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
} 