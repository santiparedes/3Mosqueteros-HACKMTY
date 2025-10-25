import SwiftUI
import UIKit

struct CardDetailsView: View {
    @StateObject private var viewModel = BankingViewModel()
    @State private var card: Card?
    @State private var balance: Double = 24092.67
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.nepTextLight)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Card display
                    CardDisplayView(card: card)
                    
                    // Balance
                    BalanceView(balance: balance)
                    
                    // Card info
                    CardInfoView(card: card)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            viewModel.loadMockData()
            card = viewModel.getActiveCard()
            balance = viewModel.getTotalBalance()
        }
    }
    
    struct CardDisplayView: View {
        let card: Card?
        
        var body: some View {
            ZStack {
                // Card background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.nepBlue, Color.nepLightBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 320, height: 200)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack {
                    HStack {
                        Spacer()
                        Text("**** 8152")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 50)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Logo
                    Image(systemName: "asterisk")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack {
                        // Contactless icon
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Debit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 25)
                }
            }
        }
    }
    
    struct BalanceView: View {
        let balance: Double
        
        var body: some View {
            VStack(spacing: 8) {
                Text("Total Balance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Text(formatCurrency(balance))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.nepTextLight)
            }
        }
        
        private func formatCurrency(_ amount: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
        }
    }
    
    struct CardInfoView: View {
        let card: Card?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Card info")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                VStack(spacing: 16) {
                    CardInfoRow(
                        title: "Card number",
                        value: card?.cardNumber ?? "5231 7252 1769 8152",
                        showCopyButton: true
                    )
                    
                    CardInfoRow(
                        title: "CVC",
                        value: card?.cvc ?? "678",
                        showCopyButton: false
                    )
                    
                    CardInfoRow(
                        title: "Expiry date",
                        value: card?.expirationDate ?? "08/29",
                        showCopyButton: false
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    struct CardInfoRow: View {
        let title: String
        let value: String
        let showCopyButton: Bool
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextLight)
                }
                
                Spacer()
                
                if showCopyButton {
                    Button(action: {
                        // Copy to clipboard
                        UIPasteboard.general.string = value
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(.nepBlue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    CardDetailsView()
}
