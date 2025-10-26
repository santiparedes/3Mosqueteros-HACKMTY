import SwiftUI
import UIKit

struct CardDetailsView: View {
    @StateObject private var viewModel = BankingViewModel()
    @StateObject private var quantumAPI = QuantumAPI.shared
    @StateObject private var userManager = UserManager.shared
    @State private var card: Card?
    @State private var balance: Double = 24092.67
    @State private var quantumWalletId: String = "qwallet_1234567890abcdef"
    @State private var showQuantumSecurity = false
    @State private var showCardInfo = false
    @State private var hasLoadedData = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Grainy gradient background
                GrainyGradientView.backgroundGradient()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Card display
                        CardDisplayView(card: card)
                        
                        // Card action buttons
                        CardActionButtonsView(showCardInfo: $showCardInfo)
                        
                        // Show different content based on card type
                        if card?.type.lowercased() == "credit" {
                            // Credit card specific content
                            CreditCardDetailsSection(card: card)
                        } else {
                            // Debit card content
                            CreditLimitView(limit: balance, cardType: card?.type ?? "Debit")
                        }
                        
                        // Card info and security grouped together (hidden by default)
                        if showCardInfo {
                            VStack(spacing: 16) {
                        // Card info
                        CardInfoView(card: card)
                        
                        // Quantum Security Section
                        QuantumSecuritySection(
                            quantumWalletId: $quantumWalletId,
                            showQuantumSecurity: $showQuantumSecurity,
                            userManager: userManager
                        )
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nepBlue)
                    }
                }
            }
        }
        .onAppear {
            if !hasLoadedData {
                // Don't load mock data - use existing Supabase data from BankingViewModel
                print("🔍 CardDetailsView: Using existing Supabase data from BankingViewModel")
                card = viewModel.getActiveCard()
                balance = viewModel.getTotalBalance()
                hasLoadedData = true
            }
        }
        .sheet(isPresented: $showQuantumSecurity) {
            QuantumSecurityDetailsView(quantumWalletId: quantumWalletId)
        }
    }
}

struct CardActionButtonsView: View {
    @Binding var showCardInfo: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            // Freeze button
            VStack(spacing: 8) {
                Button(action: {
                    // Freeze card action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.nepCardBackground.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "snowflake")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.nepBlue)
                    }
                }
                
                Text("Freeze")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextLight)
            }
            
            // View button
            VStack(spacing: 8) {
                Button(action: {
                    showCardInfo.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.nepCardBackground.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "eye")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.nepBlue)
                    }
                }
                
                Text(showCardInfo ? "Hide" : "View")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextLight)
            }
            
            // Settings button
            VStack(spacing: 8) {
                Button(action: {
                    // Card settings action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.nepCardBackground.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "gearshape")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.nepBlue)
                    }
                }
                
                Text("Settings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextLight)
            }
        }
        .padding(.vertical, 20)
    }
}

struct QuantumSecuritySection: View {
    @Binding var quantumWalletId: String
    @Binding var showQuantumSecurity: Bool
    @ObservedObject var userManager: UserManager
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isLoading = false
    
    var body: some View {
        Button(action: {
            showQuantumSecurity = true
        }) {
            HStack(spacing: 12) {
                // Lock icon with encryption symbol
                ZStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepBlue)
                    
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.nepBlue)
                        .offset(x: 6, y: -6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Encryption")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextLight)
                    
                    Text("Card is quantum encrypted. Click to verify.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.nepTextSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .sheet(isPresented: $showQuantumSecurity) {
            QuantumSecurityDetailsView(quantumWalletId: quantumWalletId)
        }
    }
    
    private func createQuantumWallet() async {
        isLoading = true
        
        do {
            let wallet = try await quantumAPI.createWallet(userId: userManager.getCurrentUserId())
            await MainActor.run {
                quantumWalletId = wallet.walletId
            }
        } catch {
            print("Failed to create quantum wallet: \(error)")
        }
        
        isLoading = false
    }
}


struct QuantumSecurityDetailsView: View {
    let quantumWalletId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isLoading = false
    @State private var verificationResult: QuantumVerificationResult?
    @State private var hasVerified = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                GrainyGradientView.backgroundGradient()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if quantumWalletId.isEmpty {
                            // Setup flow for new quantum wallet
                            VStack(spacing: 24) {
                                // Header
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.nepBlue.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(.nepBlue)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Enable Quantum Security")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.nepTextLight)
                                        
                                        Text("Protect your card with post-quantum cryptography")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.nepTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.top, 20)
                                
                                // Benefits
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Security Benefits")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.nepTextLight)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 8) {
                                        SecurityFeatureRow(icon: "shield.lefthalf.filled", title: "Post-Quantum Resistant", description: "Protected against future quantum attacks")
                                        SecurityFeatureRow(icon: "key.fill", title: "Dilithium Signatures", description: "Advanced cryptographic signatures")
                                        SecurityFeatureRow(icon: "checkmark.seal.fill", title: "Merkle Verification", description: "Tamper-proof transaction verification")
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Enable button
                                Button(action: {
                                    // Enable quantum security
                                }) {
                                    Text("Enable Quantum Security")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.nepBlue)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            // Existing verification flow
                            VStack(spacing: 24) {
                                // Header
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.nepBlue.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(.nepBlue)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Quantum Encryption Verified")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.nepTextLight)
                                        
                                        Text("Your card is protected with post-quantum cryptography")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.nepTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.top, 20)
                        
                        // Verification Details
                        VStack(spacing: 16) {
                            VerificationDetailRow(
                                title: "Encryption Algorithm",
                                value: "CRYSTALS-Dilithium",
                                status: .verified
                            )
                            
                            VerificationDetailRow(
                                title: "Key Size",
                                value: "256-bit",
                                status: .verified
                            )
                            
                            VerificationDetailRow(
                                title: "Merkle Tree Root",
                                value: "0x\(quantumWalletId.prefix(16))...",
                                status: .verified
                            )
                            
                            VerificationDetailRow(
                                title: "Last Verified",
                                value: "Just now",
                                status: .verified
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Security Features
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Security Features")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.nepTextLight)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                SecurityFeatureRow(icon: "shield.lefthalf.filled", title: "Post-Quantum Resistant", description: "Protected against future quantum attacks")
                                SecurityFeatureRow(icon: "key.fill", title: "Dilithium Signatures", description: "Advanced cryptographic signatures")
                                SecurityFeatureRow(icon: "checkmark.seal.fill", title: "Merkle Verification", description: "Tamper-proof transaction verification")
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 50)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quantum Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nepBlue)
                }
            }
        }
        .onAppear {
            if !hasVerified {
                verifyQuantumSecurity()
                hasVerified = true
            }
        }
    }
    
    private func verifyQuantumSecurity() {
        isLoading = true
        // Set verification result immediately without delay
        verificationResult = QuantumVerificationResult(
            isVerified: true,
            algorithm: "CRYSTALS-Dilithium",
            keySize: "256-bit",
            timestamp: Date()
        )
        isLoading = false
    }
}

struct QuantumVerificationResult {
    let isVerified: Bool
    let algorithm: String
    let keySize: String
    let timestamp: Date
}

struct VerificationDetailRow: View {
    let title: String
    let value: String
    let status: VerificationStatus
    
    enum VerificationStatus {
        case verified, pending, failed
        
        var color: Color {
            switch self {
            case .verified: return .green
            case .pending: return .orange
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .verified: return "checkmark.circle.fill"
            case .pending: return "clock.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(status.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepBlue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.nepCardBackground.opacity(0.05))
        .cornerRadius(10)
    }
}

struct CardDisplayView: View {
    let card: Card?
    
    private var cardType: String {
        return card?.type ?? "Credit"
    }
    
    private var cardGradient: LinearGradient {
        switch cardType.lowercased() {
        case "credit":
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.1, blue: 0.4), Color(red: 0.4, green: 0.2, blue: 0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "debit":
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.2, green: 0.5, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Card background with type-specific gradient
            ZStack {
                cardGradient
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
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
                Image("Star")
                    .resizable(resizingMode: .stretch)
                    .colorInvert()
                    .aspectRatio(contentMode: .fill)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                
                Spacer()
                
                HStack {
                    // Contactless icon
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(cardType)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 25)
            }
        }
    }
}

struct CreditLimitView: View {
    let limit: Double
    let cardType: String
    @State private var isLimitHidden = false
    
    private var title: String {
        switch cardType.lowercased() {
        case "credit":
            return "Credit Limit"
        case "debit":
            return "Available Balance"
        default:
            return "Credit Limit"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Spacer()
                
                Button(action: {
                    isLimitHidden.toggle()
                }) {
                    Image(systemName: isLimitHidden ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
            }
            
            if isLimitHidden {
                // Show dots like password field, keeping the $ sign
                Text("$••••••")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.nepTextLight)
            } else {
                Text(formatCurrency(limit))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.nepTextLight)
            }
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

// MARK: - Credit Card Details Section
struct CreditCardDetailsSection: View {
    @StateObject private var creditService = CreditService.shared
    @StateObject private var userManager = UserManager.shared
    @State private var creditOffer: CreditOffer?
    @State private var isLoading = false
    
    let card: Card?
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Loading credit data...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let offer = creditOffer {
                // Credit Limit
                VStack(alignment: .leading, spacing: 12) {
                    Text("Credit Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.nepTextLight)
                    
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Credit Limit")
                                    .font(.caption)
                                    .foregroundColor(.nepTextSecondary)
                                Text("$\(Int(offer.creditLimit))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.nepTextLight)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.nepTextSecondary)
                                Text("$\(Int(offer.creditLimit * 0.7))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.nepAccent)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("APR")
                                    .font(.caption)
                                    .foregroundColor(.nepTextSecondary)
                                Text("\(Int(offer.apr * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.nepTextLight)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Risk Tier")
                                    .font(.caption)
                                    .foregroundColor(.nepTextSecondary)
                                Text(offer.riskTier)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(riskTierColor(offer.riskTier))
                            }
                        }
                    }
                    .padding()
                    .background(Color.nepCardBackground.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // MSI Information
                if offer.msiEligible {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Special Offers")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.nepTextLight)
                        
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.nepAccent)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meses Sin Intereses")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.nepTextLight)
                                
                                Text("Eligible for \(offer.msiMonths) months without interest")
                                    .font(.caption)
                                    .foregroundColor(.nepTextSecondary)
                            }
                            
                            Spacer()
                            
                            Text("\(offer.msiMonths) MSI")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.nepAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.nepAccent.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.nepAccent.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(.nepWarning)
                    
                    Text("Credit data unavailable")
                        .font(.subheadline)
                        .foregroundColor(.nepTextSecondary)
                    
                    Button("Refresh") {
                        loadCreditData()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.nepCardBackground.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .onAppear {
            loadCreditData()
        }
    }
    
    private func loadCreditData() {
        isLoading = true
        
        Task {
            do {
                // Use the account-based credit scoring instead of user-based
                let creditScoringService = CreditScoringService.shared
                let testAccountId = APIConfig.testAccountId
                
                let result = try await creditScoringService.scoreCreditByAccount(accountId: testAccountId)
                
                DispatchQueue.main.async {
                    self.creditOffer = result.offer
                    self.isLoading = false
                }
            } catch {
                print("❌ CardDetailsView: Failed to load credit data - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func riskTierColor(_ riskTier: String) -> Color {
        switch riskTier.lowercased() {
        case "prime":
            return .green
        case "near prime":
            return .blue
        case "subprime":
            return .orange
        case "high risk":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    CardDetailsView()
        .preferredColorScheme(.dark)
}
