import SwiftUI

// MARK: - Enhanced Payment Received View
struct EnhancedPaymentReceivedView: View {
    let amount: Double
    let message: String
    let onDone: () -> Void
    
    @State private var showConfetti = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        // Confetti background
                        if showConfetti {
                            ForEach(0..<20, id: \.self) { index in
                                Circle()
                                    .fill([Color.blue, Color.green, Color.orange, Color.purple].randomElement() ?? .blue)
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: CGFloat.random(in: -100...100),
                                        y: CGFloat.random(in: -100...100)
                                    )
                                    .opacity(showConfetti ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 2.0)
                                            .delay(Double(index) * 0.1),
                                        value: showConfetti
                                    )
                            }
                        }
                        
                        // Success icon
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Money Received! 💰")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(formatCurrency(amount))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        if !message.isEmpty {
                            Text("\"\(message)\"")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .background(Color(.systemBackground))
            .navigationTitle("Payment Received")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
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
