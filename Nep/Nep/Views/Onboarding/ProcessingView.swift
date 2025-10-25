import SwiftUI

struct ProcessingView: View {
    @State private var isAnimating = false
    @State private var currentStep = 0
    
    let steps = [
        "Analizando documento...",
        "Extrayendo información...",
        "Verificando datos...",
        "Procesando imagen..."
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated processing icon
                ZStack {
                    Circle()
                        .stroke(Color.nepBlue.opacity(0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.nepBlue, Color.nepLightBlue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                    
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.nepBlue)
                }
                
                // Processing steps
                VStack(spacing: 20) {
                    Text("Procesando tu documento")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(currentStep > index ? Color.nepBlue : Color.gray.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                    
                                    if currentStep > index {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if currentStep == index {
                                        Circle()
                                            .fill(Color.nepBlue)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                                    }
                                }
                                
                                Text(steps[index])
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentStep >= index ? .white : .white.opacity(0.6))
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // Progress bar
                VStack(spacing: 12) {
                    ProgressView(value: Double(currentStep), total: Double(steps.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.nepBlue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int((Double(currentStep) / Double(steps.count)) * 100))% completado")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            startProcessing()
        }
    }
    
    private func startProcessing() {
        isAnimating = true
        
        // Simulate processing steps
        for step in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentStep = step + 1
                }
            }
        }
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    let side: IDSide
    let onRetake: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Vista previa - \(side.displayName)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: onRetake) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Tomar de nuevo")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(25)
                    }
                    
                    Button(action: onContinue) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Continuar")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nepBlue)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ProcessingView()
        .preferredColorScheme(.dark)
}
