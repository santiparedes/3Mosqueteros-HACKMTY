import SwiftUI

// MARK: - Animated Balance View
struct AnimatedBalanceView: View {
    let balance: Double
    let isVisible: Bool
    let animationDuration: Double
    let prefix: String
    let suffix: String
    
    @State private var displayBalance: Double = 0
    @State private var animationTask: Task<Void, Never>?
    
    init(
        balance: Double,
        isVisible: Bool = true,
        animationDuration: Double = 1.5,
        prefix: String = "$",
        suffix: String = ""
    ) {
        self.balance = balance
        self.isVisible = isVisible
        self.animationDuration = animationDuration
        self.prefix = prefix
        self.suffix = suffix
    }
    
    var body: some View {
        Text(formattedBalance)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.nepTextLight)
            .animation(.easeInOut(duration: 0.3), value: displayBalance)
            .onChange(of: balance) { newBalance in
                animateToNewBalance(newBalance)
            }
            .onAppear {
                displayBalance = balance
            }
    }
    
    private var formattedBalance: String {
        if !isVisible {
            return "\(prefix)••••••\(suffix)"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let formattedNumber = formatter.string(from: NSNumber(value: displayBalance)) ?? "0.00"
        return "\(prefix)\(formattedNumber)\(suffix)"
    }
    
    private func animateToNewBalance(_ newBalance: Double) {
        // Cancel any existing animation
        animationTask?.cancel()
        
        let startBalance = displayBalance
        let difference = newBalance - startBalance
        
        // If the difference is small, animate directly
        if abs(difference) < 0.01 {
            displayBalance = newBalance
            return
        }
        
        animationTask = Task {
            let steps = 60 // Number of animation steps
            let stepDuration = animationDuration / Double(steps)
            
            for step in 0...steps {
                guard !Task.isCancelled else { return }
                
                let progress = Double(step) / Double(steps)
                let easedProgress = easeInOutCubic(progress)
                
                let currentBalance = startBalance + (difference * easedProgress)
                
                await MainActor.run {
                    displayBalance = currentBalance
                }
                
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            }
            
            // Ensure we end exactly at the target balance
            await MainActor.run {
                displayBalance = newBalance
            }
        }
    }
    
    private func easeInOutCubic(_ t: Double) -> Double {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}

// MARK: - Animated Balance Card
struct AnimatedBalanceCard: View {
    let balance: Double
    let isVisible: Bool
    let onToggleVisibility: () -> Void
    
    @State private var previousBalance: Double = 0
    @State private var showBalanceChange = false
    @State private var balanceChangeAmount: Double = 0
    @State private var isPositiveChange = true
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total Balance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Spacer()
                
                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
            }
            
            HStack {
                ZStack {
                    if !isVisible {
                        // Show dots like password field, keeping the $ sign
                        Text("$ ••••••")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.nepTextLight)
                    } else {
                        AnimatedBalanceView(
                            balance: balance,
                            isVisible: isVisible,
                            animationDuration: 1.2,
                            prefix: "$ ",
                            suffix: ""
                        )
                    }
                    
                    // Balance change indicator
                    if showBalanceChange && isVisible {
                        HStack {
                            Image(systemName: isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isPositiveChange ? .green : .red)
                            
                            Text("\(isPositiveChange ? "+" : "")\(formatCurrency(abs(balanceChangeAmount)))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isPositiveChange ? .green : .red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (isPositiveChange ? Color.green : Color.red)
                                .opacity(0.1)
                        )
                        .cornerRadius(8)
                        .offset(y: -25)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showBalanceChange)
                    }
                }
                
                Spacer()
                
                // Balance trend indicator (only show when balance is visible)
                if isVisible {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.nepAccent)
                        
                        Text("+2.5%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.nepAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.nepAccent.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nepCardBackground.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepBlue.opacity(0.2), lineWidth: 1)
                )
        )
        .onChange(of: balance) { newBalance in
            handleBalanceChange(from: previousBalance, to: newBalance)
            previousBalance = newBalance
        }
        .onAppear {
            previousBalance = balance
        }
    }
    
    private func handleBalanceChange(from oldBalance: Double, to newBalance: Double) {
        let change = newBalance - oldBalance
        
        // Only show change if it's significant (more than $0.01)
        guard abs(change) > 0.01 else { return }
        
        balanceChangeAmount = change
        isPositiveChange = change > 0
        
        // Show the change indicator
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showBalanceChange = true
        }
        
        // Hide the indicator after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showBalanceChange = false
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

// MARK: - Animated Account Balance Row
struct AnimatedAccountBalanceRow: View {
    let account: Account
    let isVisible: Bool
    
    @State private var displayBalance: Double = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.nickname)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Text(account.type.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
            
            AnimatedBalanceView(
                balance: account.balance,
                isVisible: isVisible,
                animationDuration: 1.0
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nepCardBackground.opacity(0.05))
        .cornerRadius(12)
        .onChange(of: account.balance) { newBalance in
            displayBalance = newBalance
        }
        .onAppear {
            displayBalance = account.balance
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedBalanceCard(
            balance: 2450.67,
            isVisible: true,
            onToggleVisibility: {}
        )
        
        AnimatedAccountBalanceRow(
            account: Account(
                id: "test",
                nickname: "Checking",
                rewards: 0,
                balance: 1500.25,
                accountNumber: "1234",
                type: "checking",
                customerId: "test"
            ),
            isVisible: true
        )
    }
    .padding()
    .background(Color.nepDarkBackground)
    .preferredColorScheme(.dark)
}
