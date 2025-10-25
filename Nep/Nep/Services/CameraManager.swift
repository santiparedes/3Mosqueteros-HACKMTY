import AVFoundation
import UIKit
import Vision

class CameraManager: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    @Published var isSessionRunning = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "No se pudo acceder a la cámara"
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            // Configure session preset first
            if captureSession.canSetSessionPreset(.photo) {
                captureSession.sessionPreset = .photo
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // Configure video output
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            // Configure photo output
            photoOutput.isHighResolutionCaptureEnabled = true
            
            print("Camera setup completed successfully")
            
        } catch {
            print("Camera setup error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Error al configurar la cámara: \(error.localizedDescription)"
            }
        }
    }
    
    func setupPreview(in view: UIView) {
        // Create preview layer if it doesn't exist
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        
        guard let previewLayer = previewLayer else { return }
        
        // Remove from any existing superlayer
        previewLayer.removeFromSuperlayer()
        
        // Add to the new view
        view.layer.addSublayer(previewLayer)
        
        // Set frame
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
    }
    
    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Configure session preset for better performance
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            
            // Always update UI on main thread
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
                print("Camera session started: \(self.isSessionRunning)")
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
                print("Camera session stopped")
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard isSessionRunning else {
            print("Camera session not running, cannot capture photo")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        // Ensure we have a valid photo output
        guard photoOutput.availablePhotoCodecTypes.contains(.jpeg) else {
            print("JPEG codec not available")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.isHighResolutionPhotoEnabled = true
        
        print("Starting photo capture...")
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private var hasCompleted = false
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        super.init()
        
        // Add timeout to prevent hanging
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if !self.hasCompleted {
                print("Photo capture timeout")
                self.hasCompleted = true
                completion(nil)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard !hasCompleted else { return }
        hasCompleted = true
        
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to get image data from photo")
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }
        
        print("Photo captured successfully, processing...")
        
        // Process and enhance the image
        let processedImage = processImage(image)
        
        DispatchQueue.main.async {
            self.completion(processedImage)
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        // Basic image processing
        guard let cgImage = image.cgImage else { return image }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply filters for better OCR results
        let filters = [
            "CIColorControls": [
                kCIInputContrastKey: 1.2,
                kCIInputBrightnessKey: 0.1,
                kCIInputSaturationKey: 1.1
            ],
            "CISharpenLuminance": [
                kCIInputSharpnessKey: 0.5
            ]
        ]
        
        var processedImage = ciImage
        
        for (filterName, parameters) in filters {
            if let filter = CIFilter(name: filterName) {
                filter.setValue(processedImage, forKey: kCIInputImageKey)
                for (key, value) in parameters {
                    filter.setValue(value, forKey: key)
                }
                if let output = filter.outputImage {
                    processedImage = output
                }
            }
        }
        
        // Convert back to UIImage
        if let cgImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

// MARK: - Video Data Output Delegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Here you could add real-time document detection
        // For now, we'll keep it simple
    }
}
