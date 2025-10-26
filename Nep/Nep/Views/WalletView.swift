import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = BankingViewModel()
    @StateObject private var userManager = UserManager.shared
    @StateObject private var quantumBridge = QuantumNessieBridge.shared
    @State private var selectedAccountIndex = 0
    @State private var showAddMoney = false
    @State private var showSendMoney = false
    @State private var showCardDetails = false
    @State private var selectedCard: Card?
    @State private var isBalanceVisible = true
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with User Info
                    WalletHeaderView(userManager: userManager)
                    
                    // Total Balance Card
                    TotalBalanceCard(balance: getTotalBalance(), isVisible: $isBalanceVisible)
                    
                    // Quick Actions
                    QuickActionsView(
                        showAddMoney: $showAddMoney,
                        showSendMoney: $showSendMoney
                    )
                    
                    // Account Selector
                    AccountSelectorView(accounts: viewModel.accounts, selectedIndex: $selectedAccountIndex)
                    
                    // Cards Section
                    CardsSectionView(
                        cards: getCurrentUserCards(),
                        showCardDetails: $showCardDetails,
                        selectedCard: $selectedCard
                    )
                    
                    // Recent Transactions
                    RecentTransactionsView(transactions: viewModel.getRecentTransactions())
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // Don't load mock data - use existing Supabase data from BankingViewModel
            print("🔍 WalletView: Using existing Supabase data from BankingViewModel")
            Task {
                await quantumBridge.loadMockData()
            }
        }
        .sheet(isPresented: $showAddMoney) {
            AddMoneyView()
        }
        .sheet(isPresented: $showSendMoney) {
            SendMoneyView()
        }
        .sheet(isPresented: $showCardDetails) {
            CardDetailsView()
        }
    }
    
    private func getTotalBalance() -> Double {
        // Only include positive balances (checking/savings accounts)
        // Credit card balances are negative and represent debt, not available funds
        return viewModel.accounts.reduce(0) { total, account in
            if account.type.lowercased().contains("credit") {
                // For credit cards, we don't add the negative balance to total available funds
                return total
            } else {
                // For checking/savings accounts, add the positive balance
                return total + account.balance
            }
        }
    }
    
    private func getCurrentUserCards() -> [Card] {
        return viewModel.cards
    }
}

// MARK: - Header View
struct WalletHeaderView: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Wallet")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                if let user = userManager.currentUser {
                    Text("Welcome back, \(user.firstName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
            }
            
            Spacer()
            
            // Profile Avatar
            Button(action: {
                // Profile action
            }) {
                ZStack {
                    Circle()
                        .fill(Color.nepBlue)
                        .frame(width: 44, height: 44)
                    
                    if let user = userManager.currentUser {
                        Text(user.firstName.prefix(1))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Total Balance Card
struct TotalBalanceCard: View {
    let balance: Double
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total Balance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                
                Spacer()
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
            }
            
            HStack {
                if !isVisible {
                    // Show dots like password field, keeping the $ sign
                    Text("$ ••••••")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.nepTextLight)
                } else {
                    Text("$ \(formatBalance(balance))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.nepTextLight)
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
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: balance)) ?? "0.00"
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    @Binding var showAddMoney: Bool
    @Binding var showSendMoney: Bool
    
    let actions = [
        ("Add Money", "plus.circle.fill", Color.nepAccent),
        ("Send Money", "arrow.up.circle.fill", Color.nepBlue),
        ("Pay Bills", "creditcard.fill", Color.nepWarning),
        ("More", "ellipsis.circle.fill", Color.nepTextSecondary)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.nepTextLight)
            
            HStack(spacing: 16) {
                ForEach(actions, id: \.0) { action in
                    Button(action: {
                        switch action.0 {
                        case "Add Money":
                            showAddMoney = true
                        case "Send Money":
                            showSendMoney = true
                        default:
                            break
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(action.2.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: action.1)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(action.2)
                            }
                            
                            Text(action.0)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.nepTextLight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Cards Section
struct CardsSectionView: View {
    let cards: [Card]
    @Binding var showCardDetails: Bool
    @Binding var selectedCard: Card?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Cards")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View All") {
                    // View all cards action
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            if cards.isEmpty {
                EmptyCardsView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(cards) { card in
                            CardPreviewView(card: card) {
                                selectedCard = card
                                showCardDetails = true
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Card Preview
struct CardPreviewView: View {
    let card: Card
    let onTap: () -> Void
    
    private var cardGradient: LinearGradient {
        switch card.type.lowercased() {
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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(card.nickname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if card.isActive {
                        Circle()
                            .fill(Color.nepAccent)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("**** \(card.cardNumber.suffix(4))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(card.expirationDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .frame(width: 200, height: 120)
            .background(cardGradient)
            .cornerRadius(16)
        }
    }
}

// MARK: - Empty Cards View
struct EmptyCardsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.nepTextSecondary)
            
            Text("No cards yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepTextSecondary)
            
            Text("Add your first card to start making payments")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nepCardBackground.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepTextSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Recent Transactions
struct RecentTransactionsView: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View All") {
                    // View all transactions action
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            if transactions.isEmpty {
                EmptyTransactionsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(transactions.prefix(5))) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
}

// MARK: - Empty Transactions View
struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.nepTextSecondary)
            
            Text("No transactions yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.nepTextSecondary)
            
            Text("Your transaction history will appear here")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.nepTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.nepCardBackground.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.nepTextSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Placeholder Views
struct AddMoneyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Money")
                    .font(.title)
                    .padding()
                
                Text("This feature will be implemented soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Add Money")
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
    }
}

struct SendMoneyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Send Money")
                    .font(.title)
                    .padding()
                
                Text("This feature will be implemented soon")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Send Money")
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
    }
}

#Preview {
    WalletView()
}
