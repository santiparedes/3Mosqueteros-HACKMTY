import SwiftUI

struct CreditView: View {
    @StateObject private var creditService = CreditService.shared
    @StateObject private var userManager = UserManager.shared
    @State private var showingCreditApplication = false
    @State private var showingCreditHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Current Credit Offer
                    if let offer = creditService.currentOffer {
                        currentOfferSection(offer)
                    } else {
                        noOfferSection
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Credit History Preview
                    creditHistoryPreviewSection
                }
                .padding()
            }
            .navigationTitle("Credit")
            .refreshable {
                await refreshCreditScore()
            }
            .sheet(isPresented: $showingCreditApplication) {
                CreditApplicationView()
            }
            .sheet(isPresented: $showingCreditHistory) {
                CreditHistoryView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Credit Center")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Get personalized credit offers and manage your credit profile")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Current Offer Section
    private func currentOfferSection(_ offer: CreditOffer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Credit Offer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: offer.riskTierIcon)
                    .foregroundColor(Color(offer.riskTierColor))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Credit Limit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(offer.formattedCreditLimit)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("APR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(offer.formattedAPR)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Risk Tier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(offer.riskTier)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(offer.riskTierColor))
                    }
                    
                    Spacer()
                    
                    if offer.msiEligible {
                        VStack(alignment: .trailing) {
                            Text("MSI Eligible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(offer.msiMonths) months")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Explanation
                Text(offer.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - No Offer Section
    private var noOfferSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("No Credit Offer Available")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Get your personalized credit score to see available offers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Get Credit Score") {
                Task {
                    await refreshCreditScore()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(creditService.isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Apply for Credit") {
                showingCreditApplication = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Button("View History") {
                    showingCreditHistory = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Refresh Score") {
                    Task {
                        await refreshCreditScore()
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(creditService.isLoading)
            }
        }
    }
    
    // MARK: - Credit History Preview Section
    private var creditHistoryPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Applications")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingCreditHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if creditService.creditHistory.isEmpty {
                Text("No credit applications found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(creditService.creditHistory.prefix(3)) { history in
                    CreditHistoryRow(history: history)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func refreshCreditScore() async {
        guard let user = userManager.currentUser else { return }
        
        do {
            _ = try await creditService.scoreCredit(for: user)
        } catch {
            DispatchQueue.main.async {
                creditService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Credit History Row
struct CreditHistoryRow: View {
    let history: CreditHistory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Application #\(history.applicationId)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(history.appliedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(history.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(history.status.color))
                
                if let limit = history.creditLimit {
                    Text("$\(Int(limit))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

#Preview {
    CreditView()
}
