import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showNEP = false
    @State private var showLogo = false
    @State private var showContent = false
    @State private var showButtons = false
    @State private var navigateToMain = false
    @Binding var isLoggedIn: Bool
    @Binding var isOnboardingComplete: Bool
    
    @StateObject private var biometricService = BiometricAuthService.shared
    
    var body: some View {
        ZStack {
            // Grainy gradient background
            GrainyGradientView.welcomeGradient()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and NEP text
                VStack(spacing: 20) {
                    // NEP Text with custom font
                    if showNEP {
                        Image("NEP")
                            .frame(width: 40, height: 40)
                        
                    }
                    
                    // Star logo
                    if showLogo {
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
                        .shadow(radius: 5)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .scale(scale: 0.5).combined(with: .opacity)
                                
                        ))
                    }
                    
                    // Main content
                    if showContent {
                        VStack(spacing: 16) {
                            Text("TOMORROW'S BANKING IS HERE")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                }
                
                Spacer()
                
                // Action buttons
                if showButtons {
                    VStack(spacing: 16) {
                        // Try Face ID button (if biometric is available)
                        if biometricService.isAvailable {
                            Button(action: {
                                attemptBiometricAuthentication()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: biometricService.biometricIcon)
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    Text("Try \(biometricService.biometricTypeString)")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.nepBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.nepBlue.opacity(0.1))
                                .cornerRadius(28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.nepBlue, lineWidth: 2)
                                )
                            }
                        }
                        
                        Button(action: {
                            // Navigate to registration
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLoggedIn = true
                            }
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
                            // Navigate to login - go directly to main view
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLoggedIn = true
                                isOnboardingComplete = true
                            }
                        }) {
                            Text("I'm Already a Customer")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .bold()
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
        .onChange(of: biometricService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Face ID successful, go directly to main view
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoggedIn = true
                    isOnboardingComplete = true
                }
            }
        }
    }
    
    private func startAnimationSequence() {
        // Show NEP text first
        withAnimation(.easeInOut(duration: 0.5)) {
            showNEP = true
        }
        
        // Show logo after NEP
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showLogo = true
            }
        }
        
        // Start pulsing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAnimating = true
        }
        
        // Show content
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showContent = true
            }
        }
        
        // Show buttons for manual authentication (no automatic Face ID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showButtons = true
            }
        }
    }
    
    private func attemptBiometricAuthentication() {
        guard biometricService.isAvailable else {
            print("🔐 BIOMETRIC: Not available, showing buttons")
            withAnimation(.easeInOut(duration: 0.8)) {
                showButtons = true
            }
            return
        }
        
        print("🔐 BIOMETRIC: Attempting \(biometricService.biometricTypeString) authentication...")
        
        biometricService.authenticate { [self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ BIOMETRIC: Authentication successful!")
                    // The onChange modifier will handle navigation
                } else {
                    print("❌ BIOMETRIC: Authentication failed: \(error ?? "Unknown error")")
                    // Show buttons as fallback
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showButtons = true
                    }
                }
            }
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
    WelcomeView(isLoggedIn: .constant(false), isOnboardingComplete: .constant(false))
        .preferredColorScheme(.dark)
}
