import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @StateObject private var biometricAuth = BiometricAuthService.shared
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Biometric Icon with Animation
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.nepBlue.opacity(0.3),
                                    Color.nepBlue.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAuthenticating ? 1.2 : 1.0)
                        .opacity(isAuthenticating ? 0.6 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isAuthenticating
                        )
                    
                    // Biometric icon
                    Image(systemName: biometricAuth.biometricIcon)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.nepBlue)
                }
                
                // Title and Description
                VStack(spacing: 16) {
                    Text("Authenticate with \(biometricAuth.biometricTypeString)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                        .multilineTextAlignment(.center)
                    
                    Text("Use \(biometricAuth.biometricTypeString) to securely access Tap-to-Send")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Authenticate Button
                    Button(action: {
                        authenticate()
                    }) {
                        HStack(spacing: 12) {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: biometricAuth.biometricIcon)
                                    .font(.system(size: 18))
                            }
                            
                            Text(isAuthenticating ? "Authenticating..." : "Use \(biometricAuth.biometricTypeString)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.nepBlue, Color.nepBlue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.nepBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(isAuthenticating ? 0.98 : 1.0)
                    }
                    .disabled(isAuthenticating)
                    
                    // Cancel Button
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.nepTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nepCardBackground.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.nepTextSecondary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            // Start the pulsing animation immediately
            isAuthenticating = false
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("Try Again") {
                authenticate()
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        
        biometricAuth.authenticate { success, error in
            isAuthenticating = false
            
            if success {
                onSuccess()
            } else {
                // Only show error if it's not a user cancellation
                if let error = error, !error.contains("canceled") && !error.contains("Canceled") {
                    errorMessage = error
                    showError = true
                }
                // If user canceled, just close the view
                else if let error = error, (error.contains("canceled") || error.contains("Canceled")) {
                    onCancel()
                }
            }
        }
    }
}

#Preview {
    BiometricAuthView(
        onSuccess: { print("Success") },
        onCancel: { print("Cancel") }
    )
}
