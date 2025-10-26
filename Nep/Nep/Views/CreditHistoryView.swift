import SwiftUI

struct CreditHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
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
                        creditHistoryList
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
    
    // MARK: - Credit History List
    private var creditHistoryList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(creditService.creditHistory) { history in
                    CreditHistoryDetailRow(history: history)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
                                .foregroundColor(riskTierColor(riskTier))
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
