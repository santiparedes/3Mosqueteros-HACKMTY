import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraCaptureView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var showProcessing = false
    @State private var showOCRResults = false
    @State private var ocrResults: OCRResults?
    @Binding var isOnboardingComplete: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview
            if cameraManager.isSessionRunning {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                // Fallback view while camera is starting
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Iniciando cámara...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    )
            }
            
            // Overlay UI
            VStack {
                // Header
                HStack {
                    Button(action: {
                        print("DEBUG: User tapped close button")
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(22)
                    }
                    
                    Spacer()
                    
                    Text("Captura tu INE")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Debug info
                    VStack(spacing: 4) {
                        Circle()
                            .fill(capturedImage != nil ? Color.nepBlue : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                        
                        Text("INE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 60, height: 44)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(22)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                Spacer()
                
                // INE Document frame guide - moved much lower
                VStack(spacing: 20) {
                    Text("Coloca tu INE dentro del marco")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // INE-specific document frame with proper aspect ratio
                    GeometryReader { geometry in
                        let frameWidth = min(geometry.size.width * 0.8, 300) // Max 300pt width
                        let frameHeight = frameWidth * (85.6 / 53.98) // INE aspect ratio (85.6mm x 53.98mm)
                        
                        ZStack {
                            // Dark overlay outside the frame
                            Color.black.opacity(0.6)
                                .mask(
                                    Rectangle()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .frame(width: frameWidth, height: frameHeight)
                                                .blendMode(.destinationOut)
                                        )
                                )
                                .allowsHitTesting(false)
                            
                            // INE document frame
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.nepBlue, lineWidth: 3)
                                .frame(width: frameWidth, height: frameHeight)
                                .background(Color.clear)
                            
                            // Corner guides for INE
                            ForEach(0..<4) { index in
                                let cornerSize: CGFloat = 20
                                let cornerThickness: CGFloat = 3
                                
                                VStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.nepBlue)
                                        .frame(width: cornerSize, height: cornerThickness)
                                    Rectangle()
                                        .fill(Color.nepBlue)
                                        .frame(width: cornerThickness, height: cornerSize)
                                }
                                .rotationEffect(.degrees(Double(index) * 90))
                                .offset(
                                    x: index % 2 == 0 ? -(frameWidth/2 - cornerSize/2) : (frameWidth/2 - cornerSize/2),
                                    y: index < 2 ? -(frameHeight/2 - cornerSize/2) : (frameHeight/2 - cornerSize/2)
                                )
                            }
                        }
                        .frame(width: frameWidth, height: frameHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                    .frame(height: 200)
                    
                    // INE-specific instructions
                    VStack(spacing: 8) {
                        Text("Asegúrate de que toda la información sea legible")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Incluye: Nombre, CURP, fecha de nacimiento")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Capture controls - moved down
                VStack(spacing: 20) {
                    // Main capture button
                    Button(action: {
                        print("DEBUG: User tapped capture button")
                        capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .stroke(Color.nepBlue, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(Color.nepBlue)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .scaleEffect(capturedImage != nil ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: capturedImage != nil)
                    
                    // Action buttons
                    HStack(spacing: 40) {
                        // Retake button (if image exists)
                        if capturedImage != nil {
                            Button(action: {
                                print("DEBUG: User tapped retake button")
                                capturedImage = nil
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(25)
                            }
                        } else {
                            Color.clear.frame(width: 50, height: 50)
                        }
                        
                        // Continue button
                        if capturedImage != nil {
                            Button(action: {
                                print("DEBUG: User tapped continue button")
                                processImage()
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.nepBlue)
                                    .cornerRadius(25)
                            }
                        } else {
                            Color.clear.frame(width: 50, height: 50)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            print("DEBUG: CameraCaptureView appeared")
            // Start camera session with a slight delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("DEBUG: Starting camera session")
                cameraManager.startSession()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionDidStartRunning)) { _ in
            print("DEBUG: Camera session did start running")
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionDidStopRunning)) { _ in
            print("DEBUG: Camera session did stop running")
        }
        .onDisappear {
            print("DEBUG: CameraCaptureView disappeared")
            cameraManager.stopSession()
        }
        .fullScreenCover(isPresented: $showOCRResults) {
            if let results = ocrResults {
                OCRResultsView(
                    results: results,
                    onComplete: {
                        showOCRResults = false
                        isOnboardingComplete = true
                    }
                )
            }
        }
        .overlay(
            // Processing overlay
            Group {
                if showProcessing {
                    ProcessingView()
                }
            }
        )
    }
    
    private func capturePhoto() {
        print("DEBUG: Attempting to capture photo")
        
        cameraManager.capturePhoto { image in
            DispatchQueue.main.async {
                if let image = image {
                    print("DEBUG: Photo captured successfully")
                    self.capturedImage = image
                    // Skip preview, go straight to processing
                    self.processImage()
                } else {
                    print("DEBUG: Failed to capture photo")
                    // You could show an error alert here
                }
            }
        }
    }
    
    private func processImage() {
        print("DEBUG: Starting image processing")
        showProcessing = true
        
        // Process single image with OCR
        Task {
            guard let image = capturedImage else {
                print("DEBUG: No image to process")
                await MainActor.run {
                    showProcessing = false
                }
                return
            }
            
            print("DEBUG: Processing image with OCR")
            let results = await processOCR(image: image)
            
            await MainActor.run {
                print("DEBUG: OCR processing completed")
                showProcessing = false
                ocrResults = results
                showOCRResults = true
            }
        }
    }
    
    private func processOCR(image: UIImage) async -> OCRResults {
        print("DEBUG: Starting OCR processing")
        let ocrService = OCRService.shared
        
        // Process single image as front side
        let results = await ocrService.processDocument(image, side: .front)
        
        print("DEBUG: OCR results - Name: \(results.firstName) \(results.lastName), CURP: \(results.curp)")
        
        return results
    }
}


struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        cameraManager.setupPreview(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view size changes
        DispatchQueue.main.async {
            cameraManager.updatePreviewFrame(uiView.bounds)
        }
    }
}

#Preview {
    CameraCaptureView(isOnboardingComplete: .constant(false))
        .preferredColorScheme(.dark)
}
