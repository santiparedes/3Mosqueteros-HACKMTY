import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WalletView()
                .tabItem {
                    Image(systemName: "wallet.pass")
                    Text("Wallet")
                }
                .tag(0)
            
            CreditView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Credit")
                }
                .tag(1)
            
            QuantumView()
                .tabItem {
                    Image(systemName: "shield.lefthalf.filled")
                    Text("Quantum")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
