import SwiftUI

struct CreditSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
    @StateObject private var userManager = UserManager.shared
    @State private var creditOffer: CreditOffer?
    @State private var isLoading = false
    @State private var showCreditReport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Credit Overview
                    if let offer = creditOffer {
                        creditOverviewSection(offer)
                    }
                    
                    // Settings Options
                    settingsOptionsSection
                    
                    // Credit Actions
                    creditActionsSection
                }
                .padding()
            }
            .navigationTitle("Credit Settings")
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
            .fullScreenCover(isPresented: $showCreditReport) {
                CreditReportView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Credit Management")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Manage your credit profile and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Credit Overview Section
    private func creditOverviewSection(_ offer: CreditOffer) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Credit Status")
                .font(.headline)
                .fontWeight(.semibold)
            
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
                        Text("Risk Tier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(offer.riskTier)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(riskTierColor(offer.riskTier))
                    }
                }
                
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
                        Text("MSI Eligible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(offer.msiEligible ? "Yes" : "No")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(offer.msiEligible ? .green : .orange)
                    }
                }
                
                if offer.msiEligible {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.green)
                        Text("Up to \(offer.msiMonths) months without interest")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Settings Options Section
    private var settingsOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credit Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingsRow(
                    title: "Credit Monitoring",
                    subtitle: "Get alerts for credit changes",
                    icon: "bell.fill",
                    iconColor: .blue
                ) {
                    // Toggle credit monitoring
                }
                
                SettingsRow(
                    title: "Auto Payment",
                    subtitle: "Pay minimum balance automatically",
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: .green
                ) {
                    // Toggle auto payment
                }
                
                SettingsRow(
                    title: "Credit Limit Alerts",
                    subtitle: "Notify when approaching limit",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange
                ) {
                    // Toggle limit alerts
                }
                
                SettingsRow(
                    title: "MSI Notifications",
                    subtitle: "Get notified about MSI offers",
                    icon: "gift.fill",
                    iconColor: .purple
                ) {
                    // Toggle MSI notifications
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Credit Actions Section
    private var creditActionsSection: some View {
        VStack(spacing: 12) {
            Button("View Credit Report") {
                showCreditReport = true
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nepBlue)
            .foregroundColor(.nepTextLight)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 12) {
                Button("Request Limit Increase") {
                    // Navigate to limit increase
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nepCardBackground.opacity(0.1))
                .foregroundColor(.nepTextLight)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .medium))
                
                Button("Apply for New Card") {
                    // Navigate to new card application
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nepCardBackground.opacity(0.1))
                .foregroundColor(.nepTextLight)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .medium))
            }
            
            Button("Credit Education Center") {
                // Navigate to education center
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .foregroundColor(.nepTextLight)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .medium))
        }
    }
    
    // MARK: - Helper Methods
    private func loadCreditData() {
        isLoading = true
        
        Task {
            do {
                guard let user = userManager.currentUser else { return }
                let offer = try await creditService.scoreCredit(for: user)
                
                DispatchQueue.main.async {
                    self.creditOffer = offer
                    self.isLoading = false
                }
            } catch {
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

// MARK: - Settings Row Component
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    CreditSettingsView()
}
