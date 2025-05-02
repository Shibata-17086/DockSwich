import SwiftUI

struct ContentView: View {
    @ObservedObject var dockManager = DockManager.shared
    
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
            
            Text("macOSのDock表示を簡単に切り替えるアプリ")
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
                    Text(dockManager.isDockHidden ? "Dock: 非表示" : "Dock: 表示中")
                        .font(.title2)
                    
                    Spacer()
                    
                    Image(systemName: dockManager.isDockHidden ? "eye.slash" : "eye")
                        .foregroundColor(dockManager.isDockHidden ? .red : .green)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Button(action: {
                dockManager.toggleDock()
            }) {
                Text(dockManager.isDockHidden ? "Dockを表示する" : "Dockを非表示にする")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(dockManager.isDockHidden ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
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
        .frame(width: 400, height: 500)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 