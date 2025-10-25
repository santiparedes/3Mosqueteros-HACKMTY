import SwiftUI

struct DeepLinkPaymentRequestView: View {
    let deepLink: DeepLink
    @StateObject private var quantumAPI = QuantumAPI.shared
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.nepBlue)
                    
                    Text("Payment Request")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("Received via deep link")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                .padding(.top, 20)
                
                // Payment Details
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.nepTextSecondary)
                        
                        Text(formatCurrency(deepLink.amount))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.nepTextLight)
                    }
                    
                    if !deepLink.recipient.isEmpty {
                        VStack(spacing: 8) {
                            Text("From")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nepTextSecondary)
                            
                            Text(deepLink.recipient)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.nepTextLight)
                        }
                    }
                    
                    if !deepLink.message.isEmpty {
                        VStack(spacing: 8) {
                            Text("Message")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nepTextSecondary)
                            
                            Text(deepLink.message)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.nepTextLight)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .background(Color.nepCardBackground.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await processPayment()
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text("Send Payment")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.nepBlue)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.nepTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.nepCardBackground)
                            .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.nepDarkBackground)
            .navigationTitle("Deep Link Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Payment Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
        .alert("Payment Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func processPayment() async {
        isProcessing = true
        
        do {
            // Simulate processing the payment
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            
            // In a real implementation, this would integrate with your quantum payment system
            let transactionId = "tx_\(UUID().uuidString.prefix(8))"
            
            DispatchQueue.main.async {
                self.successMessage = "Payment sent successfully! Transaction ID: \(transactionId)"
                self.showSuccessAlert = true
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process payment: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
        
        isProcessing = false
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = deepLink.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    DeepLinkPaymentRequestView(
        deepLink: DeepLink(
            type: .requestMoney,
            amount: 25.00,
            currency: "USD",
            recipient: "John Doe",
            message: "Thanks for lunch!"
        )
    )
}
