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
            
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Error al configurar la cámara: \(error.localizedDescription)"
            }
        }
    }
    
    func setupPreview(in view: UIView) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
            // Set frame after adding to layer
            DispatchQueue.main.async {
                previewLayer.frame = view.bounds
            }
        }
    }
    
    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
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
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        // Process and enhance the image
        let processedImage = processImage(image)
        completion(processedImage)
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
