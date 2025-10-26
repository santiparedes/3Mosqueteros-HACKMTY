import SwiftUI

struct CreditCardDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
    @StateObject private var userManager = UserManager.shared
    @State private var creditOffer: CreditOffer?
    @State private var isLoading = false
    
    let card: Card
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Display
                    cardDisplaySection
                    
                    // Credit Details
                    creditDetailsSection
                    
                    // MSI Information
                    if let offer = creditOffer, offer.msiEligible {
                        msiSection(offer)
                    }
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Credit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCreditData()
            }
        }
    }
    
    // MARK: - Card Display Section
    private var cardDisplaySection: some View {
        VStack(spacing: 16) {
            // Credit Card Visual
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.1, blue: 0.4), Color(red: 0.4, green: 0.2, blue: 0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(card.nickname)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("**** \(card.cardNumber.suffix(4))")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(card.expirationDate)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack {
                        Text("CREDIT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        if card.isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Credit Details Section
    private var creditDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credit Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoading {
                ProgressView("Loading credit data...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let offer = creditOffer {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Credit Limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(Int(offer.creditLimit))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(Int(offer.creditLimit * 0.7))") // Assume 30% used
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("APR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(offer.apr * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Risk Tier")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(offer.riskTier)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(riskTierColor(offer.riskTier))
                        }
                    }
                    
                    // Usage bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Credit Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("30%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * 0.3, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    
                    Text("Credit data unavailable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Refresh") {
                        loadCreditData()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - MSI Section
    private func msiSection(_ offer: CreditOffer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Offers")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meses Sin Intereses")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Eligible for \(offer.msiMonths) months without interest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(offer.msiMonths) MSI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text("Use your credit card for purchases over $500 and pay in \(offer.msiMonths) equal monthly installments without interest.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button("Make Payment") {
                // Navigate to payment
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nepBlue)
            .foregroundColor(.nepTextLight)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 12) {
                Button("View Statement") {
                    // Navigate to statement
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nepCardBackground.opacity(0.1))
                .foregroundColor(.nepTextLight)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .medium))
                
                Button("Request Limit Increase") {
                    // Navigate to limit increase
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nepCardBackground.opacity(0.1))
                .foregroundColor(.nepTextLight)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadCreditData() {
        isLoading = true
        
        Task {
            do {
                guard let user = userManager.currentUser else {
                    // Use mock data if no user
                    DispatchQueue.main.async {
                        self.creditOffer = MockData.sampleCreditOffer
                        self.isLoading = false
                    }
                    return
                }
                let offer = try await creditService.scoreCredit(for: user)
                
                DispatchQueue.main.async {
                    self.creditOffer = offer
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    // Use mock data if API fails
                    self.creditOffer = MockData.sampleCreditOffer
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
    CreditCardDetailsView(card: Card(
        id: "1",
        nickname: "Credit Card",
        type: "Credit",
        accountId: "1",
        customerId: "1",
        cardNumber: "5231 7252 1769 8152",
        expirationDate: "08/29",
        cvc: "678",
        isActive: true
    ))
}
