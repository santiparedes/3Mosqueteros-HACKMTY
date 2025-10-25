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
    
    // INE-specific fields
    let curp: String
    let sex: String
    let electoralSection: String
    let locality: String
    let municipality: String
    let state: String
    let expirationDate: String
    let issueDate: String
    
    var fullName: String {
        [firstName, middleName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var isINEValid: Bool {
        return !documentNumber.isEmpty && !curp.isEmpty && !firstName.isEmpty && !lastName.isEmpty
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
        var curp = ""
        var sex = ""
        var electoralSection = ""
        var locality = ""
        var municipality = ""
        var state = ""
        var expirationDate = ""
        var issueDate = ""
        
        // INE-specific extraction patterns
        // Extract CURP (18-character alphanumeric code)
        if let curpMatch = text.range(of: #"[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]"#, options: .regularExpression) {
            curp = String(text[curpMatch])
        }
        
        // Extract document number (INE format: usually 13 digits)
        if let docMatch = text.range(of: #"[0-9]{13}"#, options: .regularExpression) {
            documentNumber = String(text[docMatch])
        }
        
        // Extract dates (DD/MM/YYYY format)
        let datePattern = #"[0-9]{2}[/-][0-9]{2}[/-][0-9]{4}"#
        let dateMatches = text.ranges(of: datePattern, options: .regularExpression)
        
        if dateMatches.count >= 1 {
            dateOfBirth = String(text[dateMatches[0]])
        }
        if dateMatches.count >= 2 {
            issueDate = String(text[dateMatches[1]])
        }
        if dateMatches.count >= 3 {
            expirationDate = String(text[dateMatches[2]])
        }
        
        // Extract sex (H/M or HOMBRE/MUJER)
        if text.contains("HOMBRE") || text.contains("H ") {
            sex = "H"
        } else if text.contains("MUJER") || text.contains("M ") {
            sex = "M"
        }
        
        // Extract electoral section
        if let sectionMatch = text.range(of: #"SECCIÓN[:\s]*[0-9]+"#, options: .regularExpression) {
            let sectionText = String(text[sectionMatch])
            if let numberMatch = sectionText.range(of: #"[0-9]+"#, options: .regularExpression) {
                electoralSection = String(sectionText[numberMatch])
            }
        }
        
        // Extract location information
        let locationKeywords = ["LOCALIDAD", "MUNICIPIO", "ESTADO"]
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            if cleanLine.contains("LOCALIDAD") {
                // Get the next line as locality
                if index + 1 < lines.count {
                    locality = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if cleanLine.contains("MUNICIPIO") {
                // Get the next line as municipality
                if index + 1 < lines.count {
                    municipality = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if cleanLine.contains("ESTADO") {
                // Get the next line as state
                if index + 1 < lines.count {
                    state = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Extract names using INE-specific patterns
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
            
            // Look for INE name patterns
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
        
        // Set nationality for INE (Mexican)
        nationality = "Mexicana"
        
        return OCRResults(
            firstName: firstName,
            lastName: lastName,
            middleName: middleName,
            dateOfBirth: dateOfBirth,
            documentNumber: documentNumber,
            nationality: nationality,
            address: address,
            occupation: "",
            incomeSource: "",
            curp: curp,
            sex: sex,
            electoralSection: electoralSection,
            locality: locality,
            municipality: municipality,
            state: state,
            expirationDate: expirationDate,
            issueDate: issueDate
        )
    }
    
    private func parseBackSide(text: String, lines: [String]) -> OCRResults {
        var address = ""
        
        // Look for address patterns on INE back side
        let addressKeywords = ["DOMICILIO", "DIRECCION", "CALLE", "COLONIA", "CP", "C.P.", "CÓDIGO POSTAL"]
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for keyword in addressKeywords {
                if cleanLine.contains(keyword) {
                    // Try to get the next few lines as address
                    let addressLines = lines.suffix(from: index).prefix(4)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && !$0.contains(keyword) }
                    
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
            incomeSource: "",
            curp: "",
            sex: "",
            electoralSection: "",
            locality: "",
            municipality: "",
            state: "",
            expirationDate: "",
            issueDate: ""
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
        incomeSource: "",
        curp: "",
        sex: "",
        electoralSection: "",
        locality: "",
        municipality: "",
        state: "",
        expirationDate: "",
        issueDate: ""
    )
}

extension String {
    func ranges(of pattern: String, options: String.CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: pattern, options: options, range: searchStartIndex..<self.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}
