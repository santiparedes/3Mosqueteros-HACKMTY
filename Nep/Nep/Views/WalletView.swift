import SwiftUI

struct WalletView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "wallet.pass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Wallet View")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is a placeholder for the wallet functionality")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wallet")
        }
    }
}

#Preview {
    WalletView()
}
