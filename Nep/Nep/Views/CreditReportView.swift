import SwiftUI

struct CreditReportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared
    @StateObject private var userManager = UserManager.shared
    @State private var isLoading = false
    @State private var creditScore: Int = 0
    @State private var creditLimit: Double = 0
    @State private var riskTier: String = "Unknown"
    @State private var msiEligible: Bool = false
    @State private var msiMonths: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nepDarkBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Credit Overview Grid
                        creditOverviewGrid
                        
                       
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.nepTextLight)
                    }
                }
            }
            .onAppear {
                loadCreditData()
            }
        }
    }
    
    // MARK: - Headeredit reportr Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Credit Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.nepTextLight)
            
            Text("Current credit status and recommendations")
                .font(.subheadline)
                .foregroundColor(.nepTextSecondary)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Credit Overview Grid
    private var creditOverviewGrid: some View {
        VStack(spacing: 32) {
            // Big Credit Score Card on top
            bigCreditScoreCard
            
            // Tips Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Tips for How to Improve")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.nepTextLight)
                
                // 4 Tip Cards in 2x2 grid
                VStack(spacing: 16) {
                    // Top row
                    HStack(spacing: 16) {
                        tipCard1
                        tipCard2
                    }
                    
                    // Bottom row
                    HStack(spacing: 16) {
                        tipCard3
                        tipCard4
                    }
                }
            }
        }
    }
    
    // MARK: - Big Credit Score Card
    private var bigCreditScoreCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Credit Score")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Text("Credit Limit")
                    .font(.caption)
                    .foregroundColor(.nepTextSecondary)
            }
            
            // Main content
            HStack(spacing: 20) {
                // Credit Score Wheel
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.nepCardBackground.opacity(0.3), lineWidth: 16)
                        .frame(width: 140, height: 140)
                    
                    // Progress circle with gradient
                    Circle()
                        .trim(from: 0, to: CGFloat(creditScore) / 850)
                        .stroke(
                            LinearGradient(
                                colors: [.nepError, .nepWarning, .nepAccent, .nepBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: creditScore)
                    
                    // Score text
                    VStack(spacing: 4) {
                        Text("\(creditScore)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.nepTextLight)
                        
                        Text(scoreDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(scoreColor)
                    }
                }
                
                // Credit Info
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(Int(creditLimit))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.nepTextLight)
                        
                        Text("Available Credit")
                            .font(.caption)
                            .foregroundColor(.nepTextSecondary)
                    }
                    .padding(.leading, 14)
                    
                    if msiEligible {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(msiMonths) MSI")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.nepAccent)
                            
                            Text("Months without interest")
                                .font(.caption)
                                .foregroundColor(.nepTextSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    
    // MARK: - Tip Card 1
    private var tipCard1: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.nepBlue)
                
                Text("Pay on Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.nepTextLight)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextSecondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Tip Card 2
    private var tipCard2: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.nepWarning)
                
                Text("Lower Usage")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.nepTextLight)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextSecondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Tip Card 3
    private var tipCard3: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 30))
                    .foregroundColor(.nepAccent)
                
                Text("Build History")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.nepTextLight)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextSecondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Tip Card 4
    private var tipCard4: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "eye.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.nepBlue)
                
                Text("Monitor Credit")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.nepTextLight)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextSecondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(16)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(16)
    }
    
    
    
    // MARK: - Computed Properties
    private var scoreColor: Color {
        switch creditScore {
        case 750...850:
            return .nepAccent
        case 700...749:
            return .nepBlue
        case 650...699:
            return .nepWarning
        case 600...649:
            return .nepError
        default:
            return .nepError
        }
    }
    
    private var scoreDescription: String {
        switch creditScore {
        case 750...850:
            return "Excellent"
        case 700...749:
            return "Good"
        case 650...699:
            return "Fair"
        case 600...649:
            return "Fair"
        default:
            return "Fair"
        }
    }
    
    private var riskTierColor: Color {
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
    
    
    // MARK: - Helper Methods
    private func loadCreditData() {
        isLoading = true
        
        Task {
            do {
                guard let user = userManager.currentUser else { return }
                let offer = try await creditService.scoreCredit(for: user)
                
                DispatchQueue.main.async {
                    // Convert PD90 score to credit score (inverse relationship)
                    // PD90 of 0.1 = 750+ score, PD90 of 0.5 = 600 score, etc.
                    let pd90 = offer.pd90Score
                    self.creditScore = max(300, min(850, Int(850 - (pd90 * 500))))
                    self.creditLimit = offer.creditLimit
                    self.riskTier = offer.riskTier
                    self.msiEligible = offer.msiEligible
                    self.msiMonths = offer.msiMonths
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    // Use default values if API fails
                    self.creditScore = 650
                    self.creditLimit = 5000
                    self.riskTier = "Fair"
                    self.msiEligible = false
                    self.msiMonths = 0
                    self.isLoading = false
                }
            }
        }
    }
}


#Preview {
    CreditReportView()
}
