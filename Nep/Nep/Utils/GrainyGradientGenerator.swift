import UIKit
import CoreImage
import SwiftUI

// MARK: - UIColor Extension for SwiftUI Color
extension UIColor {
    convenience init(_ color: Color) {
        let resolvedColor = UIColor(color)
        self.init(cgColor: resolvedColor.cgColor)
    }
}

// MARK: - Core Image Grainy Gradient Generator
class GrainyGradientGenerator {
    // Shared context for performance - reuse across calls
    private static let sharedContext = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB),
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)
    ])
    
    /// Creates a high-quality grainy gradient image using Core Image
    /// - Parameters:
    ///   - size: Output image size
    ///   - color0: Starting color of the gradient
    ///   - color1: Ending color of the gradient
    ///   - angle: Gradient angle in radians (0 = horizontal, π/2 = vertical)
    ///   - grainAmount: Grain strength (0.0 = no grain, 1.0 = maximum grain)
    ///   - grainScale: Grain size scale (0.1 = fine grain, 2.0 = coarse grain)
    ///   - contrast: Noise contrast (0.5 = low contrast, 2.0 = high contrast)
    /// - Returns: UIImage with grainy gradient, nil if generation fails
    static func makeGrainyGradientImage(
        size: CGSize,
        color0: UIColor,
        color1: UIColor,
        angle: CGFloat = 0,
        grainAmount: Float = 1,
        grainScale: CGFloat = 1.0,
        contrast: Float = 1.2
    ) -> UIImage? {
        
        // Create base gradient
        guard let gradientFilter = CIFilter(name: "CILinearGradient") else { return nil }
        
        // Calculate gradient direction based on angle
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = sqrt(pow(size.width, 2) + pow(size.height, 2)) / 2
        
        let startX = centerX - radius * cosAngle
        let startY = centerY - radius * sinAngle
        let endX = centerX + radius * cosAngle
        let endY = centerY + radius * sinAngle
        
        gradientFilter.setValue(CIVector(x: startX, y: startY), forKey: "inputPoint0")
        gradientFilter.setValue(CIVector(x: endX, y: endY), forKey: "inputPoint1")
        gradientFilter.setValue(CIColor(color: color0), forKey: "inputColor0")
        gradientFilter.setValue(CIColor(color: color1), forKey: "inputColor1")
        
        guard let gradientImage = gradientFilter.outputImage else { return nil }
        
        // Create noise/grain
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return nil }
        guard let noiseImage = noiseFilter.outputImage else { return nil }
        
        // Scale the noise to control grain size
        let scaleTransform = CGAffineTransform(scaleX: grainScale, y: grainScale)
        let scaledNoise = noiseImage.transformed(by: scaleTransform)
        
        // Adjust noise contrast
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(scaledNoise, forKey: kCIInputImageKey)
        contrastFilter.setValue(NSNumber(value: contrast), forKey: kCIInputContrastKey)
        contrastFilter.setValue(NSNumber(value: 0.0), forKey: kCIInputBrightnessKey)
        contrastFilter.setValue(NSNumber(value: 1.0), forKey: kCIInputSaturationKey)
        
        guard let contrastedNoise = contrastFilter.outputImage else { return nil }
        
        // Apply color matrix to control grain amount
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        colorMatrixFilter.setValue(contrastedNoise, forKey: kCIInputImageKey)
        colorMatrixFilter.setValue(CIVector(x: CGFloat(grainAmount), y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: CGFloat(grainAmount), z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(grainAmount), w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(grainAmount)), forKey: "inputAVector")
        
        guard let grainImage = colorMatrixFilter.outputImage else { return nil }
        
        // Blend grain with gradient using Overlay blend mode
        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return nil }
        blendFilter.setValue(gradientImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(grainImage, forKey: kCIInputImageKey)
        
        guard let blendedImage = blendFilter.outputImage else { return nil }
        
        // Crop to requested size
        let cropRect = CGRect(origin: .zero, size: size)
        let croppedImage = blendedImage.cropped(to: cropRect)
        
        // Render to UIImage
        guard let cgImage = sharedContext.createCGImage(croppedImage, from: cropRect) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

// MARK: - SwiftUI Integration
struct GrainyGradientView: View {
    let color0: Color
    let color1: Color
    let angle: CGFloat
    let grainAmount: Float
    let grainScale: CGFloat
    let contrast: Float
    
    @State private var gradientImage: UIImage?
    
    init(
        color0: Color,
        color1: Color,
        angle: CGFloat = 0,
        grainAmount: Float = 0.3,
        grainScale: CGFloat = 1.0,
        contrast: Float = 1.2
    ) {
        self.color0 = color0
        self.color1 = color1
        self.angle = angle
        self.grainAmount = grainAmount
        self.grainScale = grainScale
        self.contrast = contrast
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Use fallback gradient for previews and initial load
            LinearGradient(
                gradient: Gradient(colors: [color0, color1]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .overlay(
                // Add subtle noise overlay for grain effect
                NoiseOverlay(
                    intensity: grainAmount,
                    scale: grainScale,
                    color0: color0,
                    color1: color1
                )
            )
        }
    }
    
    private func generateGradient() {
        Task {
            let size = CGSize(width: 400, height: 400) // Generate at reasonable resolution
            let uiColor0 = UIColor(color0)
            let uiColor1 = UIColor(color1)
            
            let image = GrainyGradientGenerator.makeGrainyGradientImage(
                size: size,
                color0: uiColor0,
                color1: uiColor1,
                angle: angle,
                grainAmount: grainAmount,
                grainScale: grainScale,
                contrast: contrast
            )
            
            await MainActor.run {
                self.gradientImage = image
            }
        }
    }
}

// MARK: - Simple Noise Overlay for Previews
struct NoiseOverlay: View {
    let intensity: Float
    let scale: CGFloat
    let color0: Color
    let color1: Color
    
    init(intensity: Float, scale: CGFloat, color0: Color = Color.nepBlue, color1: Color = Color.nepLightBlue) {
        self.intensity = intensity
        self.scale = scale
        self.color0 = color0
        self.color1 = color1
    }
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let gridSize = 1.0 * scale // Much smaller grain
                let width = Int(size.width / gridSize)
                let height = Int(size.height / gridSize)
                
                for x in 0..<width {
                    for y in 0..<height {
                        let noiseValue = Double.random(in: 0...1)
                        
                        if noiseValue > (1.0 - Double(intensity)) {
                            let rect = CGRect(
                                x: Double(x) * gridSize,
                                y: Double(y) * gridSize,
                                width: gridSize,
                                height: gridSize
                            )
                            
                            // Interpolate color based on position
                            let position = (Double(x) / Double(width) + Double(y) / Double(height)) / 2.0
                            let color = position < 0.5 ? color0 : color1
                            
                            context.opacity = noiseValue * 0.2 // Much more subtle
                            context.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Extensions
extension GrainyGradientView {
    /// Card gradient with blue tones and subtle grain
    static func cardGradient() -> GrainyGradientView {
        GrainyGradientView(
            color0: Color.nepBlue,
            color1: Color.nepLightBlue,
            angle: .pi / 4, // 45 degrees
            grainAmount: 0.1,
            grainScale: 0.5,
            contrast: 1.0
        )
    }
    
    /// Background gradient with dark to blue transition
    static func backgroundGradient() -> GrainyGradientView {
        GrainyGradientView(
            color0: Color.nepDarkBackground,
            color1: Color.nepDarkBlue,
            angle: .pi / 6, // 30 degrees
            grainAmount: 0.05,
            grainScale: 0.3,
            contrast: 0.8
        )
    }
    
    /// Welcome screen gradient
    static func welcomeGradient() -> GrainyGradientView {
        GrainyGradientView(
            color0: Color.nepDarkBackground,
            color1: Color.nepBlue,
            angle: .pi / 3, // 60 degrees
            grainAmount: 0.08,
            grainScale: 0.4,
            contrast: 0.9
        )
    }
}

// MARK: - Performance Tips
/*
 PERFORMANCE TIPS:
 
 1. CACHE GRADIENTS: Store generated images in a cache to avoid regenerating identical gradients
 2. REUSE CONTEXT: The shared CIContext is already optimized for reuse
 3. PRE-GENERATE: Generate common gradients at app launch
 4. LOWER RESOLUTION: Use smaller sizes for backgrounds, higher for cards
 5. ASYNC GENERATION: Always generate on background thread, update UI on main thread
 
 CONVERT TO LIVE BACKGROUND:
 To use as a live UIView background:
 
 let gradientView = GrainyGradientView.cardGradient()
 let hostingController = UIHostingController(rootView: gradientView)
 view.addSubview(hostingController.view)
 hostingController.view.frame = view.bounds
 hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
 
 TUNING KNOBS:
 - grainAmount: 0.1 (subtle) to 0.5 (heavy grain)
 - grainScale: 0.5 (fine) to 2.0 (coarse grain)
 - contrast: 0.8 (soft) to 1.5 (sharp grain)
 - angle: 0 (horizontal) to π/2 (vertical)
 */
