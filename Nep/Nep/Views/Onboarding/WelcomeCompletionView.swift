import SwiftUI

struct WelcomeCompletionView: View {
    let userName: String
    let userPhoto: UIImage?
    let onComplete: () -> Void
    
    @State private var showContent = false
    @State private var showPhoto = false
    @State private var showWelcomeText = false
    @State private var showButtons = false
    @State private var animationOffset: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.nepBlue.opacity(0.2),
                    Color.nepBlue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ParticleBackgroundView()
                .opacity(0.3)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // User photo with animation
                    if let photo = userPhoto {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.nepBlue, Color.nepBlue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(showPhoto ? 1.0 : 0.1)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showPhoto)
                            
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .scaleEffect(showPhoto ? 1.0 : 0.1)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showPhoto)
                        }
                    } else {
                        // Fallback avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.nepBlue, Color.nepBlue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(showPhoto ? 1.0 : 0.1)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showPhoto)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.white)
                                .scaleEffect(showPhoto ? 1.0 : 0.1)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showPhoto)
                        }
                    }
                    
                    // Welcome text
                    VStack(spacing: 16) {
                        Text("Welcome to Nep!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(showWelcomeText ? 1.0 : 0.0)
                            .offset(y: showWelcomeText ? 0 : animationOffset)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: showWelcomeText)
                        
                        Text("Hello, \(userName)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.nepBlue)
                            .multilineTextAlignment(.center)
                            .opacity(showWelcomeText ? 1.0 : 0.0)
                            .offset(y: showWelcomeText ? 0 : animationOffset)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: showWelcomeText)
                        
                        Text("Your digital banking account is ready")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .opacity(showWelcomeText ? 1.0 : 0.0)
                            .offset(y: showWelcomeText ? 0 : animationOffset)
                            .animation(.easeOut(duration: 0.8).delay(0.8), value: showWelcomeText)
                    }
                    
                    // Features preview
                    VStack(spacing: 16) {
                        WelcomeFeatureRow(
                            icon: "creditcard.fill",
                            title: "Digital Card",
                            description: "Immediate access to your virtual card"
                        )
                        
                        WelcomeFeatureRow(
                            icon: "wave.3.right",
                            title: "Quick Payments",
                            description: "Send money with just a tap"
                        )
                        
                        WelcomeFeatureRow(
                            icon: "shield.fill",
                            title: "Quantum Security",
                            description: "Bank-level protection"
                        )
                    }
                    .opacity(showWelcomeText ? 1.0 : 0.0)
                    .offset(y: showWelcomeText ? 0 : animationOffset)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: showWelcomeText)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        onComplete()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                            
                            Text("Get Started")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.nepBlue, Color.nepBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .scaleEffect(showButtons ? 1.0 : 0.8)
                    .opacity(showButtons ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: showButtons)
                    
                    Button(action: {
                        // Show app tour or help
                    }) {
                        Text("Learn more about Nep")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(showButtons ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: showButtons)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPhoto = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showWelcomeText = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showButtons = true
        }
    }
}

struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.nepBlue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.nepBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ParticleBackgroundView: View {
    @State private var particles: [WelcomeParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.nepBlue.opacity(0.1))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .animation(
                            .linear(duration: particle.duration)
                            .repeatForever(autoreverses: false),
                            value: particle.position
                        )
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            WelcomeParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.1...0.3),
                duration: Double.random(in: 3...8)
            )
        }
        
        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
            }
        }
    }
}

struct WelcomeParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

#Preview {
    WelcomeCompletionView(
        userName: "John Doe",
        userPhoto: nil,
        onComplete: { }
    )
    .preferredColorScheme(.dark)
}
