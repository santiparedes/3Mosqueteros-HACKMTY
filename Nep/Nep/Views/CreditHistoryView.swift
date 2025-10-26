import SwiftUI

struct CreditHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
    @StateObject private var creditScoringService = CreditScoringService.shared
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nepDarkBackground
                    .ignoresSafeArea()
                
                VStack {
                    if isLoading {
                        ProgressView("Loading credit history...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.nepTextLight)
                    } else if creditService.creditHistory.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Current Credit Score Section
                                if let currentScore = creditScoringService.currentCreditScore {
                                    currentCreditScoreSection(currentScore)
                                }
                                
                                // Credit History List
                                creditHistoryList
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Credit History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nepTextLight)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshHistory()
                    }
                    .disabled(isLoading)
                    .foregroundColor(.nepTextLight)
                }
            }
            .onAppear {
                refreshHistory()
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.nepTextSecondary)
            
            Text("No Credit History")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.nepTextLight)
            
            Text("You haven't applied for any credit products yet. Start by applying for a credit card or loan.")
                .font(.subheadline)
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Apply for Credit") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nepBlue)
            .foregroundColor(.nepTextLight)
            .cornerRadius(12)
            .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Current Credit Score Section
    private func currentCreditScoreSection(_ score: CreditScoreResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Credit Analysis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.nepTextLight)
            
            VStack(spacing: 12) {
                // Score Overview
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Risk Tier")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text(score.offer.riskTier)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Self.riskTierColor(score.offer.riskTier))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("PD90 Score")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("\(String(format: "%.1f", score.offer.pd90Score * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Self.pd90ScoreColor(score.offer.pd90Score))
                    }
                }
                
                Divider()
                    .background(Color.nepTextSecondary.opacity(0.3))
                
                // Credit Details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Credit Limit")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("$\(Int(score.offer.creditLimit))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.nepTextLight)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("APR")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("\(Int(score.offer.apr * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.nepTextLight)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("\(String(format: "%.0f", score.offer.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                
                // Model Info
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    
                    Text("Model: \(score.modelVersion)")
                        .font(.caption)
                        .foregroundColor(.nepTextSecondary)
                    
                    Spacer()
                    
                    Text(DateFormatter.localizedString(from: score.scoredAt, dateStyle: .short, timeStyle: .short))
                        .font(.caption)
                        .foregroundColor(.nepTextSecondary)
                }
                
                // Explanation
                Text(score.offer.explanation)
                    .font(.caption)
                    .foregroundColor(.nepTextSecondary)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Credit History List
    private var creditHistoryList: some View {
        VStack(spacing: 16) {
            Text("Credit Applications")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.nepTextLight)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(creditService.creditHistory) { history in
                CreditHistoryDetailRow(history: history)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func refreshHistory() {
        isLoading = true
        
        Task {
            do {
                let history = try await creditService.getCreditHistory()
                DispatchQueue.main.async {
                    creditService.creditHistory = history
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    static func riskTierColor(_ riskTier: String) -> Color {
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
    
    static func pd90ScoreColor(_ score: Double) -> Color {
        // PD90 score is probability of default in 90 days (lower is better)
        if score < 0.05 { // Less than 5%
            return .green
        } else if score < 0.15 { // Less than 15%
            return .blue
        } else if score < 0.30 { // Less than 30%
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Credit History Detail Row
struct CreditHistoryDetailRow: View {
    let history: CreditHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Application #\(history.applicationId)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.nepTextLight)
                    
                    Text(formatDate(history.appliedDate))
                        .font(.subheadline)
                        .foregroundColor(.nepTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(status: history.status)
            }
            
            // Details
            if let limit = history.creditLimit, let apr = history.apr {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Credit Limit")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("$\(Int(limit))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.nepTextLight)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("APR")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                        Text("\(Int(apr * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.nepTextLight)
                    }
                    
                    if let riskTier = history.riskTier {
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Risk Tier")
                                .font(.caption)
                                .foregroundColor(.nepTextSecondary)
                            Text(riskTier)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(CreditHistoryView.riskTierColor(riskTier))
                        }
                    }
                }
            }
            
            // Notes
            if let notes = history.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.nepTextSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: CreditApplicationStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.nepTextLight)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .approved:
            return .nepAccent
        case .pending:
            return .nepWarning
        case .rejected:
            return .nepError
        case .underReview:
            return .nepBlue
        case .requiresDocuments:
            return .nepWarning
        }
    }
}

#Preview {
    CreditHistoryView()
}
