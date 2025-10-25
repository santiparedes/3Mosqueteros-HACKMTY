import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Transaction icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? transaction.payee.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Text(transaction.medium.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(transaction.amount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(transaction.isDebit ? .nepError : .nepAccent)
                
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nepCardBackground.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch transaction.type.lowercased() {
        case "transfer":
            return "person.circle"
        case "purchase":
            if transaction.payee.name.lowercased().contains("uber") {
                return "car"
            } else if transaction.payee.name.lowercased().contains("shoprite") {
                return "cart"
            } else if transaction.payee.name.lowercased().contains("glovo") {
                return "location"
            }
            return "creditcard"
        default:
            return "creditcard"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch transaction.type.lowercased() {
        case "transfer":
            return Color.nepAccent.opacity(0.2)
        case "purchase":
            return Color.nepWarning.opacity(0.2)
        default:
            return Color.nepTextSecondary.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        switch transaction.type.lowercased() {
        case "transfer":
            return .nepAccent
        case "purchase":
            return .nepWarning
        default:
            return .nepTextSecondary
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    VStack {
        TransactionRow(transaction: Transaction.mockTransactions[0])
        TransactionRow(transaction: Transaction.mockTransactions[1])
        TransactionRow(transaction: Transaction.mockTransactions[2])
    }
    .padding()
    .background(Color.nepDarkBackground)
}
