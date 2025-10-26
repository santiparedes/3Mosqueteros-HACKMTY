import SwiftUI
import AVFoundation
import Vision
import UIKit
import AudioToolbox

struct CameraCaptureView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var capturedImage: UIImage?
    @State private var currentSide: IDSide = .front
    @State private var showProcessing = false
    @State private var showOCRResults = false
    @State private var ocrResults: OCRResults?
    @State private var showCaptureFlash = false
    @State private var showCaptureCheckmark = false
    @Binding var isOnboardingComplete: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview
            if cameraManager.isSessionRunning {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Fallback view while camera is starting
                Color.black
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            
            // Capture flash animation
            if showCaptureFlash {
                Color.white
                    .ignoresSafeArea(.all)
                    .opacity(0.8)
                    .animation(.easeOut(duration: 0.1), value: showCaptureFlash)
            }
            
            // Capture success checkmark
            if showCaptureCheckmark {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                                .scaleEffect(showCaptureCheckmark ? 1.0 : 0.1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCaptureCheckmark)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(showCaptureCheckmark ? 1.0 : 0.1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1), value: showCaptureCheckmark)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
            
            // Overlay UI - Properly distributed across screen
            VStack(spacing: 0) {
                // Header - Top section
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
                    
                    Text(currentSide == .front ? "Frente de tu INE" : "Reverso de tu INE")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Progress indicator
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(frontImage != nil ? Color.nepBlue : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(backImage != nil ? Color.nepBlue : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                        
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
                .padding(.bottom, 20)
                
                // Middle section - Combined instructions at top
                VStack(spacing: 16) {
                    Text(currentSide == .front ? 
                         "Coloca el FRENTE de tu INE dentro del marco. Asegúrate de que toda la información sea legible." :
                         "Ahora voltea tu INE y coloca el REVERSO dentro del marco. Asegúrate de que toda la información sea legible.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(nil)
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                // Document frame - centered
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
                    }
                    .frame(width: frameWidth, height: frameHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(height: 300)
                
                Spacer()
                
                // Bottom section - Capture controls at very bottom
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
                                frontImage = nil
                                backImage = nil
                                currentSide = .front
                                showCaptureFlash = false
                                showCaptureCheckmark = false
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
                .padding(.bottom, -70)
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
                AIChatView(
                    ocrResults: results,
                    onDataConfirmed: { confirmedResults in
                        // Data has been confirmed by user
                        print("DEBUG: Data confirmed by user")
                    },
                    onPhotoCaptured: { photo in
                        // User photo has been captured
                        print("DEBUG: User photo captured")
                        // Photo captured, but let AIChatView handle the welcome screen flow
                        // Don't complete onboarding here - let AIChatView show the welcome screen
                    },
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
        print("DEBUG: Attempting to capture photo for \(currentSide == .front ? "front" : "back") side")
        
        // Haptic feedback for capture
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Camera shutter sound
        AudioServicesPlaySystemSound(1108) // Camera shutter sound
        
        // Trigger capture animations
        withAnimation(.easeInOut(duration: 0.1)) {
            showCaptureFlash = true
        }
        
        // Hide flash after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                showCaptureFlash = false
            }
        }
        
        // Show success checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showCaptureCheckmark = true
            }
        }
        
        // Hide checkmark after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCaptureCheckmark = false
            }
        }
        
        cameraManager.capturePhoto { image in
            DispatchQueue.main.async {
                if let image = image {
                    print("DEBUG: Photo captured successfully for \(self.currentSide == .front ? "front" : "back") side")
                    
                    // Set capturedImage for UI compatibility
                    self.capturedImage = image
                    
                    if self.currentSide == .front {
                        self.frontImage = image
                        // Switch to back side
                        self.currentSide = .back
                        print("DEBUG: Switching to back side capture")
                    } else {
                        self.backImage = image
                        // Both sides captured, process both
                        self.processBothImages()
                    }
                } else {
                    print("DEBUG: Failed to capture photo")
                    // Hide animations on failure
                    self.showCaptureFlash = false
                    self.showCaptureCheckmark = false
                }
            }
        }
    }
    
    private func processBothImages() {
        print("DEBUG: Starting dual-side image processing")
        showProcessing = true
        
        // Process both images with OCR
        Task {
            guard let front = frontImage, let back = backImage else {
                print("DEBUG: Missing front or back image")
                await MainActor.run {
                    showProcessing = false
                }
                return
            }
            
            print("DEBUG: Processing both sides with OCR")
            let results = await processBothSidesOCR(frontImage: front, backImage: back)
            
            await MainActor.run {
                print("DEBUG: Dual-side OCR processing completed")
                showProcessing = false
                ocrResults = results
                showOCRResults = true
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
    
    private func processBothSidesOCR(frontImage: UIImage, backImage: UIImage) async -> OCRResults {
        print("DEBUG: Starting dual-side OCR processing")
        let ocrService = OCRService.shared
        
        // Process both sides using the new method
        let results = await ocrService.processBothSides(frontImage: frontImage, backImage: backImage)
        
        print("DEBUG: Dual-side OCR results - Name: \(results.firstName) \(results.lastName), CURP: \(results.curp)")
        print("DEBUG: Address: \(results.address), Electoral: \(results.electoralSection)")
        
        return results
    }
}


struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.contentMode = .scaleAspectFill
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
