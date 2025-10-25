//
//  ContentView.swift
//  Nep
//
//  Created by Santiago Paredes on 24/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuantumBankingView()
                .tabItem {
                    Image(systemName: "shield.lefthalf.filled")
                    Text("Quantum Banking")
                }
                .tag(0)
            
            WalletView()
                .tabItem {
                    Image(systemName: "wallet.pass")
                    Text("Wallet")
                }
                .tag(1)
            
            QuantumView()
                .tabItem {
                    Image(systemName: "atom")
                    Text("Quantum")
                }
                .tag(2)
            
            CreditView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Credit")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
