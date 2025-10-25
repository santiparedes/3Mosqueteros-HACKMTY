import SwiftUI
import AVFoundation

struct ConsentView: View {
    @State private var cameraConsent = false
    @State private var showCamera = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        ZStack {
            // Background
            GrainyGradientView.welcomeGradient()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Bienvenido a Nep")
                            .font(.custom("BrunoACESC-regular", size: 36))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Para completar tu registro, necesitamos verificar tu identidad")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 60)
                    
                    // INE Card Image
                    VStack(spacing: 16) {
                        Image("animacion1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("Ejemplo de INE")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    
                    // Next Steps Instructions
                    VStack(spacing: 16) {
                        Text("📋 Próximos pasos")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(
                                number: "1",
                                text: "Capturaremos una foto de tu INE (frente y reverso)"
                            )
                            InstructionRow(
                                number: "2", 
                                text: "Extraeremos automáticamente tus datos personales"
                            )
                            InstructionRow(
                                number: "3",
                                text: "Verificaremos tu identidad de forma segura"
                            )
                            InstructionRow(
                                number: "4",
                                text: "Completaremos tu registro bancario"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Camera Consent
                    VStack(spacing: 20) {
                        ConsentCard(
                            icon: "camera.fill",
                            title: "Acceso a la Cámara",
                            description: "Necesitamos acceso a tu cámara para capturar fotos de tu identificación oficial (INE, pasaporte, etc.)",
                            isConsented: $cameraConsent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy Notice
                    VStack(spacing: 12) {
                        Text("🔒 Tus datos están protegidos")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("• Encriptación de extremo a extremo\n• Cumplimiento con GDPR y LFPDPPP\n• No compartimos datos con terceros\n• Puedes eliminar tus datos en cualquier momento")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    Spacer(minLength: 40)
                    
                    // Action Button
                    Button(action: {
                        handleConsent()
                    }) {
                        HStack {
                            Text("Continuar con Verificación")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.nepBlue, Color.nepLightBlue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .disabled(!cameraConsent)
                    .opacity(cameraConsent ? 1.0 : 0.6)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(isOnboardingComplete: $isOnboardingComplete)
        }
        .alert("Permisos Requeridos", isPresented: $showAlert) {
            Button("Configuración") {
                openAppSettings()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleConsent() {
        guard cameraConsent else { return }
        
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    showCamera = true
                } else {
                    alertMessage = "Necesitamos acceso a la cámara para capturar tu identificación. Por favor, habilita el permiso en Configuración."
                    showAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.nepBlue)
                .cornerRadius(12)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct ConsentCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isConsented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.nepBlue)
                    .frame(width: 40, height: 40)
                    .background(Color.nepBlue.opacity(0.1))
                    .cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: {
                    isConsented.toggle()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isConsented ? Color.nepBlue : Color.clear)
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.nepBlue, lineWidth: 2)
                            )
                        
                        if isConsented {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isConsented ? Color.nepBlue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ConsentView(isOnboardingComplete: .constant(false))
        .preferredColorScheme(.dark)
}
