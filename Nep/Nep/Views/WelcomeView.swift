import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Grainy gradient background
            GrainyGradientView.welcomeGradient()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 20) {
                    //  logo
                    ZStack {
                        Circle()
                            .fill(Color.nepBlue)
                            .frame(width: 120, height: 120)
                        
                        Image("Star")
                            .resizable(resizingMode: .stretch)
                            .aspectRatio(contentMode: .fill)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 90)
                            .colorInvert()
                        
                    }
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Main text
                    VStack(spacing: 16) {
                        Text("TOMORROW'S BANKING IS HERE")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Text("Experience banking reimagined for the digital age — secure, intuitive, and built for the way you live today.")
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white .opacity(0.5))
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Navigate to registration
                    }) {
                        Text("Become a Customer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.nepTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        // Navigate to login
                    }) {
                        Text("I Am Already a Customer")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white .opacity(0.5))
                            .bold()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct GridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let spacing: CGFloat = 20
                
                // Vertical lines
                for i in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: height))
                }
                
                // Horizontal lines
                for i in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: width, y: i))
                }
            }
            .stroke(Color.nepBlue.opacity(0.1), lineWidth: 0.5)
        }
    }
}

#Preview {
    WelcomeView()
        .preferredColorScheme(.dark)
}
