import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraCaptureView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var currentSide: IDSide = .front
    @State private var capturedImages: [IDSide: UIImage] = [:]
    @State private var showImagePreview = false
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
                    
                    Text("Captura de \(currentSide == .front ? "Frente" : "Reverso")")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Progress indicator and debug info
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            ForEach(IDSide.allCases, id: \.self) { side in
                                Circle()
                                    .fill(capturedImages[side] != nil ? Color.nepBlue : Color.white.opacity(0.5))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Debug info
                        Text(cameraManager.isSessionRunning ? "Cámara activa" : "Cámara inactiva")
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
                
                // Document frame guide
                VStack(spacing: 20) {
                    Text("Coloca tu identificación dentro del marco")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Document frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.nepBlue, lineWidth: 3)
                            .frame(width: 280, height: 180)
                            .background(Color.clear)
                        
                        // Corner guides
                        ForEach(0..<4) { index in
                            Rectangle()
                                .fill(Color.nepBlue)
                                .frame(width: 20, height: 3)
                                .rotationEffect(.degrees(Double(index) * 90))
                                .offset(
                                    x: index % 2 == 0 ? 0 : 130,
                                    y: index < 2 ? 0 : 130
                                )
                        }
                    }
                    
                    Text("Asegúrate de que toda la información sea legible")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Capture controls
                HStack(spacing: 40) {
                    // Retake button (if image exists)
                    if capturedImages[currentSide] != nil {
                        Button(action: {
                            capturedImages[currentSide] = nil
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(30)
                        }
                    }
                    
                    // Capture button
                    Button(action: {
                        capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .stroke(Color.nepBlue, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                    // Next/Continue button
                    if capturedImages[currentSide] != nil {
                        Button(action: {
                            if currentSide == .front {
                                currentSide = .back
                            } else {
                                processImages()
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.nepBlue)
                                .cornerRadius(30)
                        }
                    } else {
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Start camera session with a slight delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cameraManager.startSession()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionDidStartRunning)) { _ in
            print("Camera session did start running")
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVCaptureSessionDidStopRunning)) { _ in
            print("Camera session did stop running")
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            ImagePreviewView(
                image: capturedImages[currentSide] ?? UIImage(),
                side: currentSide,
                onRetake: {
                    capturedImages[currentSide] = nil
                    showImagePreview = false
                },
                onContinue: {
                    showImagePreview = false
                    if currentSide == .front {
                        currentSide = .back
                    } else {
                        processImages()
                    }
                }
            )
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
        cameraManager.capturePhoto { image in
            if let image = image {
                capturedImages[currentSide] = image
                showImagePreview = true
            }
        }
    }
    
    private func processImages() {
        showProcessing = true
        
        // Process both images with OCR
        Task {
            let frontImage = capturedImages[.front]
            let backImage = capturedImages[.back]
            
            let results = await processOCR(frontImage: frontImage, backImage: backImage)
            
            await MainActor.run {
                showProcessing = false
                ocrResults = results
                showOCRResults = true
            }
        }
    }
    
    private func processOCR(frontImage: UIImage?, backImage: UIImage?) async -> OCRResults {
        let ocrService = OCRService.shared
        
        var frontResults = OCRResults.empty
        var backResults = OCRResults.empty
        
        if let frontImage = frontImage {
            frontResults = await ocrService.processDocument(frontImage, side: .front)
        }
        
        if let backImage = backImage {
            backResults = await ocrService.processDocument(backImage, side: .back)
        }
        
        // Combine results from both sides
        return OCRResults(
            firstName: frontResults.firstName,
            lastName: frontResults.lastName,
            middleName: frontResults.middleName,
            dateOfBirth: frontResults.dateOfBirth,
            documentNumber: frontResults.documentNumber,
            nationality: frontResults.nationality,
            address: backResults.address.isEmpty ? frontResults.address : backResults.address,
            occupation: "",
            incomeSource: ""
        )
    }
}

enum IDSide: CaseIterable {
    case front, back
    
    var displayName: String {
        switch self {
        case .front: return "Frente"
        case .back: return "Reverso"
        }
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
