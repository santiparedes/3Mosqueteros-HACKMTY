import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = BankingViewModel()
    @State private var selectedAccountIndex = 0
    
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView()
                    
                    // Currency balances
                    CurrencyBalancesView()
                    
                    // Main balance
                    MainBalanceView(balance: getCurrentBalance())
                    
                    // Account selector
                    AccountSelectorView(accounts: viewModel.accounts, selectedIndex: $selectedAccountIndex)
                    
                    // Action buttons
                    ActionButtonsView()
                    
                    // Transactions
                    TransactionsView(transactions: viewModel.getRecentTransactions())
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            viewModel.loadMockData()
        }
    }
    
    private func getCurrentBalance() -> Double {
        guard selectedAccountIndex < viewModel.accounts.count else { return 0.0 }
        return viewModel.accounts[selectedAccountIndex].balance
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.nepTextSecondary)
                Text("Q Search")
                    .foregroundColor(.nepTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.nepCardBackground)
            .cornerRadius(25)
            
            Spacer()
            
            // Notification and profile icons
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(.nepTextLight)
                }
                
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.nepTextLight)
                }
            }
        }
    }
}

struct CurrencyBalancesView: View {
    let currencies = [
        ("USD", "🇺🇸", 24092.67),
        ("EUR", "🇪🇺", 7805.91),
        ("AUD", "🇦🇺", 3693.70)
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(currencies, id: \.0) { currency in
                CurrencyCard(
                    flag: currency.1,
                    amount: currency.2,
                    currency: currency.0
                )
            }
        }
    }
}

struct CurrencyCard: View {
    let flag: String
    let amount: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(flag)
                .font(.system(size: 24))
            
            Text(formatCurrency(amount, currency: currency))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.nepTextLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.nepBlue.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct MainBalanceView: View {
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

struct AccountSelectorView: View {
    let accounts: [Account]
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4) { index in
                AccountCard(
                    isSelected: index == selectedIndex,
                    isActive: index < accounts.count,
                    account: index < accounts.count ? accounts[index] : nil
                )
                .onTapGesture {
                    if index < accounts.count {
                        selectedIndex = index
                    }
                }
            }
        }
    }
}

struct AccountCard: View {
    let isSelected: Bool
    let isActive: Bool
    let account: Account?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.nepBlue : Color.nepCardBackground)
                .frame(width: 60, height: 40)
            
            if isActive {
                if isSelected {
                    Image(systemName: "asterisk")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "creditcard")
                        .font(.system(size: 16))
                        .foregroundColor(.nepTextSecondary)
                }
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                    .foregroundColor(.nepTextSecondary)
            }
        }
    }
}

struct ActionButtonsView: View {
    let actions = [
        ("ADD", "plus"),
        ("SEND", "arrow.up"),
        ("CONVERT", "arrow.left.arrow.right"),
        ("MORE", "ellipsis")
    ]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(actions, id: \.0) { action in
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.nepCardBackground)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: action.1)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.nepTextLight)
                    }
                    
                    Text(action.0)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nepTextLight)
                }
            }
        }
    }
}

struct TransactionsView: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transactions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Button("View all") {
                    // Navigate to all transactions
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.nepBlue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
