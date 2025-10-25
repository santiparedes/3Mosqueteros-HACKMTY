import Vision
import UIKit
import Foundation

struct OCRResults {
    let firstName: String
    let lastName: String
    let middleName: String
    let dateOfBirth: String
    let documentNumber: String
    let nationality: String
    let address: String
    let occupation: String
    let incomeSource: String
    
    var fullName: String {
        [firstName, middleName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

class OCRService: ObservableObject {
    static let shared = OCRService()
    
    private init() {}
    
    func processDocument(_ image: UIImage, side: IDSide) async -> OCRResults {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: OCRResults.empty)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("OCR Error: \(error.localizedDescription)")
                    continuation.resume(returning: OCRResults.empty)
                    return
                }
                
                let results = self.extractTextFromObservations(request.results as? [VNRecognizedTextObservation] ?? [])
                let ocrResults = self.parseDocumentData(results, side: side)
                continuation.resume(returning: ocrResults)
            }
            
            // Configure for better accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["es", "en"] // Spanish and English
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error.localizedDescription)")
                continuation.resume(returning: OCRResults.empty)
            }
        }
    }
    
    private func extractTextFromObservations(_ observations: [VNRecognizedTextObservation]) -> [String] {
        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }
    
    private func parseDocumentData(_ textLines: [String], side: IDSide) -> OCRResults {
        let fullText = textLines.joined(separator: " ").uppercased()
        
        switch side {
        case .front:
            return parseFrontSide(text: fullText, lines: textLines)
        case .back:
            return parseBackSide(text: fullText, lines: textLines)
        }
    }
    
    private func parseFrontSide(text: String, lines: [String]) -> OCRResults {
        var firstName = ""
        var lastName = ""
        var middleName = ""
        var dateOfBirth = ""
        var documentNumber = ""
        var nationality = ""
        var address = ""
        
        // Extract document number (usually contains letters and numbers)
        if let docMatch = text.range(of: #"[A-Z]{2,3}[0-9]{6,10}"#, options: .regularExpression) {
            documentNumber = String(text[docMatch])
        }
        
        // Extract date of birth (DD/MM/YYYY or DD-MM-YYYY format)
        if let dobMatch = text.range(of: #"[0-9]{2}[/-][0-9]{2}[/-][0-9]{4}"#, options: .regularExpression) {
            dateOfBirth = String(text[dobMatch])
        }
        
        // Extract nationality
        let nationalityKeywords = ["MEXICANA", "MEXICANO", "MEX", "MEXICO"]
        for keyword in nationalityKeywords {
            if text.contains(keyword) {
                nationality = "Mexicana"
                break
            }
        }
        
        // Extract names (look for common name patterns)
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip lines that are too short or contain only numbers/special chars
            if cleanLine.count < 3 {
                continue
            }
            
            // Skip lines that contain only numbers/special chars
            if cleanLine.range(of: #"^[0-9\s\-/]+$"#, options: .regularExpression) != nil {
                continue
            }
            
            // Look for name patterns
            if cleanLine.contains("NOMBRE") || cleanLine.contains("APELLIDO") {
                let nameComponents = cleanLine.components(separatedBy: .whitespaces)
                    .filter { $0.count > 2 && !$0.contains("NOMBRE") && !$0.contains("APELLIDO") }
                
                if nameComponents.count >= 2 {
                    firstName = nameComponents[0]
                    lastName = nameComponents.last ?? ""
                    if nameComponents.count > 2 {
                        middleName = nameComponents[1]
                    }
                }
            }
        }
        
        // If no explicit name labels found, try to extract from first few lines
        if firstName.isEmpty {
            let potentialNames = lines.prefix(3).compactMap { line in
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let hasOnlyNumbers = cleanLine.range(of: #"^[0-9\s\-/]+$"#, options: .regularExpression) != nil
                return cleanLine.count > 3 && !hasOnlyNumbers ? cleanLine : nil
            }
            
            if potentialNames.count >= 2 {
                firstName = potentialNames[0]
                lastName = potentialNames[1]
            }
        }
        
        return OCRResults(
            firstName: firstName,
            lastName: lastName,
            middleName: middleName,
            dateOfBirth: dateOfBirth,
            documentNumber: documentNumber,
            nationality: nationality,
            address: address,
            occupation: "",
            incomeSource: ""
        )
    }
    
    private func parseBackSide(text: String, lines: [String]) -> OCRResults {
        var address = ""
        
        // Look for address patterns
        let addressKeywords = ["DOMICILIO", "DIRECCION", "CALLE", "COLONIA", "CP", "C.P."]
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for keyword in addressKeywords {
                if cleanLine.contains(keyword) {
                    // Try to get the next few lines as address
                    let addressLines = lines.suffix(from: index).prefix(3)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    address = addressLines.joined(separator: " ")
                    break
                }
            }
            
            if !address.isEmpty { break }
        }
        
        return OCRResults(
            firstName: "",
            lastName: "",
            middleName: "",
            dateOfBirth: "",
            documentNumber: "",
            nationality: "",
            address: address,
            occupation: "",
            incomeSource: ""
        )
    }
}

extension OCRResults {
    static let empty = OCRResults(
        firstName: "",
        lastName: "",
        middleName: "",
        dateOfBirth: "",
        documentNumber: "",
        nationality: "",
        address: "",
        occupation: "",
        incomeSource: ""
    )
}
