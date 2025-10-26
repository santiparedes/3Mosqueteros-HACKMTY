import Vision
import UIKit
import Foundation

enum IDSide {
    case front, back
}

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
    
    func processBothSides(frontImage: UIImage, backImage: UIImage) async -> OCRResults {
        print("DEBUG: OCRService - Processing both INE sides")
        print("DEBUG: OCRService - Front image size: \(frontImage.size), Back image size: \(backImage.size)")
        
        // Process both sides concurrently to improve performance
        async let frontResults = processDocument(frontImage, side: .front)
        async let backResults = processDocument(backImage, side: .back)
        
        let (front, back) = await (frontResults, backResults)
        
        print("DEBUG: OCRService - Front side results: \(front.firstName) \(front.lastName)")
        print("DEBUG: OCRService - Back side results: address=\(back.address), electoral=\(back.electoralSection)")
        
        // Combine results - front side has priority for personal info, back side for additional data
        return OCRResults(
            firstName: front.firstName,
            lastName: front.lastName,
            middleName: front.middleName,
            dateOfBirth: front.dateOfBirth,
            documentNumber: back.documentNumber.isEmpty ? front.documentNumber : back.documentNumber,
            nationality: front.nationality,
            address: back.address.isEmpty ? front.address : back.address,
            occupation: front.occupation,
            incomeSource: front.incomeSource,
            curp: front.curp,
            sex: front.sex,
            electoralSection: front.electoralSection.isEmpty ? back.electoralSection : front.electoralSection,
            locality: back.locality.isEmpty ? front.locality : back.locality,
            municipality: back.municipality.isEmpty ? front.municipality : back.municipality,
            state: back.state.isEmpty ? front.state : back.state,
            expirationDate: front.expirationDate,
            issueDate: front.issueDate
        )
    }
    
    func processDocument(_ image: UIImage, side: IDSide) async -> OCRResults {
        print("DEBUG: OCRService - Starting document processing with Vision Framework")
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                print("DEBUG: OCRService - No CGImage available")
                continuation.resume(returning: OCRResults.empty)
                return
            }
            
            // First, try to detect the document rectangle
            let documentRequest = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    print("DEBUG: OCRService - Document detection error: \(error.localizedDescription)")
                    // Fallback to direct OCR
                    self.performOCR(on: cgImage, continuation: continuation, side: side)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      let documentRect = observations.first else {
                    print("DEBUG: OCRService - No document detected, using full image")
                    // Fallback to direct OCR
                    self.performOCR(on: cgImage, continuation: continuation, side: side)
                    return
                }
                
                print("DEBUG: OCRService - Document detected, cropping and processing")
                // Crop the image to the detected document
                if let croppedImage = self.cropImage(cgImage, to: documentRect) {
                    self.performOCR(on: croppedImage, continuation: continuation, side: side)
                } else {
                    self.performOCR(on: cgImage, continuation: continuation, side: side)
                }
            }
            
            // Configure document detection
            documentRequest.minimumAspectRatio = 0.5
            documentRequest.maximumAspectRatio = 2.0
            documentRequest.minimumSize = 0.1
            documentRequest.maximumObservations = 1
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([documentRequest])
            } catch {
                print("DEBUG: OCRService - Failed to perform document detection: \(error.localizedDescription)")
                // Fallback to direct OCR
                self.performOCR(on: cgImage, continuation: continuation, side: side)
            }
        }
    }
    
    private func performOCR(on cgImage: CGImage, continuation: CheckedContinuation<OCRResults, Never>, side: IDSide) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("DEBUG: OCRService - Error: \(error.localizedDescription)")
                continuation.resume(returning: OCRResults.empty)
                return
            }
            
            let results = self.extractTextFromObservations(request.results as? [VNRecognizedTextObservation] ?? [])
            print("DEBUG: OCRService - Extracted text: \(results.prefix(200))...")
            let ocrResults = self.parseDocumentData(results, side: side)
            print("DEBUG: OCRService - Parsed results - Name: \(ocrResults.firstName) \(ocrResults.lastName), CURP: \(ocrResults.curp)")
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
            print("DEBUG: OCRService - Failed to perform OCR: \(error.localizedDescription)")
            continuation.resume(returning: OCRResults.empty)
        }
    }
    
    private func cropImage(_ cgImage: CGImage, to observation: VNRectangleObservation) -> CGImage? {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Convert normalized coordinates to image coordinates
        let topLeft = CGPoint(x: observation.topLeft.x * imageSize.width, y: (1 - observation.topLeft.y) * imageSize.height)
        let topRight = CGPoint(x: observation.topRight.x * imageSize.width, y: (1 - observation.topRight.y) * imageSize.height)
        let bottomLeft = CGPoint(x: observation.bottomLeft.x * imageSize.width, y: (1 - observation.bottomLeft.y) * imageSize.height)
        let bottomRight = CGPoint(x: observation.bottomRight.x * imageSize.width, y: (1 - observation.bottomRight.y) * imageSize.height)
        
        // Calculate crop rectangle
        let minX = min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)
        let maxX = max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)
        let maxY = max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)
        
        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        return cgImage.cropping(to: cropRect)
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
        
        // Extract VIGENCIA field (issue and expiration dates)
        if let vigenciaMatch = text.range(of: #"VIGENCIA[:\s]*(\d{4})\s*-\s*(\d{4})"#, options: .regularExpression) {
            let vigenciaText = String(text[vigenciaMatch])
            let vigenciaNumbers = vigenciaText.ranges(of: #"\d{4}"#, options: .regularExpression)
            if vigenciaNumbers.count >= 2 {
                issueDate = String(vigenciaText[vigenciaNumbers[0]])
                expirationDate = String(vigenciaText[vigenciaNumbers[1]])
            }
        }
        
        // Fallback to date matches if VIGENCIA not found
        if issueDate.isEmpty && dateMatches.count >= 2 {
            issueDate = String(text[dateMatches[1]])
        }
        if expirationDate.isEmpty && dateMatches.count >= 3 {
            expirationDate = String(text[dateMatches[2]])
        }
        
        // Extract sex (H/M or HOMBRE/MUJER)
        if text.contains("HOMBRE") || text.contains("SEXO H") {
            sex = "Masculino"
        } else if text.contains("MUJER") || text.contains("SEXO M") {
            sex = "Femenino"
        }
        
        // Extract electoral section
        if let sectionMatch = text.range(of: #"SECCIÓN[:\s]*[0-9]+"#, options: .regularExpression) {
            let sectionText = String(text[sectionMatch])
            if let numberMatch = sectionText.range(of: #"[0-9]+"#, options: .regularExpression) {
                electoralSection = String(sectionText[numberMatch])
            }
        }
        
        // Extract location information from address lines
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for address patterns that contain municipality and state
            if cleanLine.contains(",") && (cleanLine.contains("N.L.") || cleanLine.contains("CDMX") || cleanLine.contains("JAL") || cleanLine.contains("VER") || cleanLine.contains("PUE")) {
                // Parse "MONTERREY, N.L." format
                let components = cleanLine.components(separatedBy: ",")
                if components.count >= 2 {
                    municipality = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    state = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Extract locality from address lines (look for "COL" pattern)
            if cleanLine.contains("COL ") && locality.isEmpty {
                let addressParts = cleanLine.components(separatedBy: " ")
                if let colIndex = addressParts.firstIndex(of: "COL") {
                    // Get all parts after "COL" until we hit a number or municipality
                    var localityParts: [String] = []
                    for j in (colIndex + 1)..<addressParts.count {
                        let nextPart = addressParts[j]
                        // Stop if we hit a number (postal code) or municipality
                        if nextPart.range(of: #"^\d+$"#, options: .regularExpression) != nil ||
                           nextPart.contains("MONTERREY") || nextPart.contains("CDMX") ||
                           nextPart.contains("GUADALAJARA") || nextPart.contains("PUEBLA") {
                            break
                        }
                        localityParts.append(nextPart)
                    }
                    locality = localityParts.joined(separator: " ")
                }
            }
            
            // Look for explicit location keywords
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
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip lines that are too short or contain only numbers/special chars
            if cleanLine.count < 3 {
                continue
            }
            
            // Skip lines that contain only numbers/special chars
            if cleanLine.range(of: #"^[0-9\s\-/]+$"#, options: .regularExpression) != nil {
                continue
            }
            
            // Skip header lines (MÉXICO, INSTITUTO, etc.)
            if cleanLine.contains("MÉXICO") || cleanLine.contains("INSTITUTO") || 
               cleanLine.contains("NACIONAL") || cleanLine.contains("ELECTORAL") ||
               cleanLine.contains("CREDENCIAL") || cleanLine.contains("VOTAR") {
                continue
            }
            
            // Look for the actual name before "NOMBRE" field
            if cleanLine.contains("NOMBRE") {
                // Look backwards for the name (usually appears before "NOMBRE")
                for i in stride(from: index - 1, through: max(0, index - 3), by: -1) {
                    let nameLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Check if this looks like a name (not a field label)
                    if nameLine.count > 2 && nameLine.count < 20 &&
                       !nameLine.contains("MÉXICO") && !nameLine.contains("INSTITUTO") &&
                       !nameLine.contains("CREDENCIAL") && !nameLine.contains("NOMBRE") &&
                       !nameLine.contains("DOMICILIO") && !nameLine.contains("CLAVE") &&
                       !nameLine.contains("CURP") && !nameLine.contains("FECHA") &&
                       !nameLine.contains("SECCIÓN") && !nameLine.contains("VIGENCIA") &&
                       !nameLine.contains("SEXO") && !nameLine.contains("AÑO") &&
                       !nameLine.contains("REGISTRO") && nameLine.range(of: #"^[A-ZÁÉÍÓÚÑa-záéíóúñ\s]+$"#, options: .regularExpression) != nil {
                        
                        let nameComponents = nameLine.components(separatedBy: .whitespaces)
                            .filter { $0.count > 1 }
                        
                        if nameComponents.count >= 2 {
                            firstName = nameComponents[0]
                            // Join all remaining components as last name (apellidos)
                            let surnameComponents = Array(nameComponents.dropFirst())
                            lastName = surnameComponents.joined(separator: " ")
                            middleName = ""
                            break
                        }
                    }
                }
                break
            }
        }
        
        // If still no name found, look for any standalone name pattern
        if firstName.isEmpty {
            for (index, line) in lines.enumerated() {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Look for any standalone name (not a field label)
                if cleanLine.count > 2 && cleanLine.count < 20 && 
                   !cleanLine.contains("MÉXICO") && !cleanLine.contains("INSTITUTO") &&
                   !cleanLine.contains("CREDENCIAL") && !cleanLine.contains("NOMBRE") &&
                   !cleanLine.contains("DOMICILIO") && !cleanLine.contains("CLAVE") &&
                   !cleanLine.contains("CURP") && !cleanLine.contains("FECHA") &&
                   !cleanLine.contains("SECCIÓN") && !cleanLine.contains("VIGENCIA") &&
                   !cleanLine.contains("SEXO") && !cleanLine.contains("AÑO") &&
                   !cleanLine.contains("REGISTRO") && cleanLine.range(of: #"^[A-ZÁÉÍÓÚÑa-záéíóúñ]+$"#, options: .regularExpression) != nil {
                    
                    firstName = cleanLine
                    
                    // Look for the next lines that might be surnames
                    var surnames: [String] = []
                    for i in (index + 1)..<min(index + 6, lines.count) {
                        let nextLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Skip if it's a field label
                        if nextLine.contains("DOMICILIO") || nextLine.contains("CLAVE") ||
                           nextLine.contains("CURP") || nextLine.contains("FECHA") ||
                           nextLine.contains("SECCIÓN") || nextLine.contains("VIGENCIA") ||
                           nextLine.contains("SEXO") || nextLine.contains("AÑO") ||
                           nextLine.contains("REGISTRO") || nextLine == "NOMBRE" {
                            continue // Skip but don't break, keep looking
                        }
                        
                        // If it looks like a surname (all caps, letters only, not too short)
                        // Avoid duplicating the first name
                        if nextLine.count > 2 && nextLine.range(of: #"^[A-ZÁÉÍÓÚÑ]+$"#, options: .regularExpression) != nil &&
                           nextLine.uppercased() != firstName.uppercased() {
                            surnames.append(nextLine)
                        }
                    }
                    
                    if surnames.count >= 1 {
                        // Join all surnames as last name
                        lastName = surnames.joined(separator: " ")
                        middleName = "" // No middle name for INE format
                    }
                    break
                }
            }
        }
        
        // Alternative approach: Look for the sequence after "NOMBRE"
        if firstName.isEmpty {
            for (index, line) in lines.enumerated() {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if cleanLine == "NOMBRE" {
                    // Look for names in the next few lines
                    var names: [String] = []
                    for i in (index + 1)..<min(index + 5, lines.count) {
                        let nextLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Skip field labels
                        if nextLine.contains("DOMICILIO") || nextLine.contains("CLAVE") ||
                           nextLine.contains("CURP") || nextLine.contains("FECHA") ||
                           nextLine.contains("SECCIÓN") || nextLine.contains("VIGENCIA") ||
                           nextLine.contains("SEXO") || nextLine.contains("AÑO") ||
                           nextLine.contains("REGISTRO") {
                            break
                        }
                        
                        // If it looks like a name (all caps, letters only, reasonable length)
                        if nextLine.count > 2 && nextLine.count < 20 && 
                           nextLine.range(of: #"^[A-ZÁÉÍÓÚÑ]+$"#, options: .regularExpression) != nil {
                            names.append(nextLine)
                        }
                    }
                    
                    if names.count >= 1 {
                        firstName = names[0]
                        if names.count >= 2 {
                            lastName = names[1]
                        }
                        if names.count >= 3 {
                            middleName = names[2]
                        }
                    }
                    break
                }
            }
        }
        
        // If no explicit name labels found, try to extract from lines that look like names
        if firstName.isEmpty {
            // Look for lines that appear after "NOMBRE" but before other fields
            var foundNombre = false
            for line in lines {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if cleanLine.contains("NOMBRE") {
                    foundNombre = true
                    continue
                }
                
                // Skip header lines
                if cleanLine.contains("MÉXICO") || cleanLine.contains("INSTITUTO") || 
                   cleanLine.contains("NACIONAL") || cleanLine.contains("ELECTORAL") ||
                   cleanLine.contains("CREDENCIAL") || cleanLine.contains("VOTAR") ||
                   cleanLine.contains("DOMICILIO") || cleanLine.contains("CLAVE") ||
                   cleanLine.contains("CURP") || cleanLine.contains("AÑO") ||
                   cleanLine.contains("FECHA") || cleanLine.contains("SECCIÓN") ||
                   cleanLine.contains("VIGENCIA") || cleanLine.contains("SEXO") {
                    continue
                }
                
                // If we found NOMBRE and this looks like a name, extract it
                if foundNombre && cleanLine.count > 3 && 
                   cleanLine.range(of: #"^[A-ZÁÉÍÓÚÑ\s]+$"#, options: .regularExpression) != nil {
                    let nameComponents = cleanLine.components(separatedBy: .whitespaces)
                        .filter { $0.count > 1 }
                    
                    if nameComponents.count >= 2 {
                        firstName = nameComponents[0]
                        lastName = nameComponents.last ?? ""
                        if nameComponents.count > 2 {
                            middleName = nameComponents[1]
                        }
                        break
                    }
                }
            }
        }
        
        // Final fallback: look for any line that looks like a name
        if firstName.isEmpty {
            for line in lines {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip header lines and field labels
                if cleanLine.contains("MÉXICO") || cleanLine.contains("INSTITUTO") || 
                   cleanLine.contains("NACIONAL") || cleanLine.contains("ELECTORAL") ||
                   cleanLine.contains("CREDENCIAL") || cleanLine.contains("VOTAR") ||
                   cleanLine.contains("DOMICILIO") || cleanLine.contains("CLAVE") ||
                   cleanLine.contains("CURP") || cleanLine.contains("AÑO") ||
                   cleanLine.contains("FECHA") || cleanLine.contains("SECCIÓN") ||
                   cleanLine.contains("VIGENCIA") || cleanLine.contains("SEXO") ||
                   cleanLine.contains("NOMBRE") {
                    continue
                }
                
                // Check if this looks like a name (contains letters, not just numbers/special chars)
                if cleanLine.count > 3 && cleanLine.range(of: #"^[A-ZÁÉÍÓÚÑ\s]+$"#, options: .regularExpression) != nil {
                    let nameComponents = cleanLine.components(separatedBy: .whitespaces)
                        .filter { $0.count > 1 }
                    
                    if nameComponents.count >= 2 {
                        firstName = nameComponents[0]
                        lastName = nameComponents.last ?? ""
                        if nameComponents.count > 2 {
                            middleName = nameComponents[1]
                        }
                        break
                    }
                }
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
        var electoralSection = ""
        var locality = ""
        var municipality = ""
        var state = ""
        var documentNumber = ""
        var additionalInfo = ""
        
        // Look for address patterns on INE back side
        let addressKeywords = ["DOMICILIO", "DIRECCION", "CALLE", "COLONIA", "CP", "C.P.", "CÓDIGO POSTAL"]
        let electoralKeywords = ["SECCIÓN", "SECCION", "ELECTORAL", "DISTRITO", "CASILLA"]
        let locationKeywords = ["LOCALIDAD", "MUNICIPIO", "ESTADO", "DELEGACIÓN"]
        
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract address information
            if address.isEmpty {
                for keyword in addressKeywords {
                    if cleanLine.contains(keyword) {
                        // Try to get the next few lines as address
                        let addressLines = lines.suffix(from: index).prefix(4)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty && !$0.contains(keyword) }
                        
                        address = addressLines.joined(separator: " ")
                        
                        // Extract locality from address (complete name)
                        let addressParts = address.components(separatedBy: " ")
                        if addressParts.count >= 2 {
                            // Look for patterns like "COL LOS CRISTALES" or "LA SILLA"
                            for (i, part) in addressParts.enumerated() {
                                if part == "COL" && i + 1 < addressParts.count {
                                    // Get all parts after "COL" until we hit a number or municipality
                                    var localityParts: [String] = []
                                    for j in (i + 1)..<addressParts.count {
                                        let nextPart = addressParts[j]
                                        // Stop if we hit a number (postal code) or municipality
                                        if nextPart.range(of: #"^\d+$"#, options: .regularExpression) != nil ||
                                           nextPart.contains("MONTERREY") || nextPart.contains("CDMX") ||
                                           nextPart.contains("GUADALAJARA") || nextPart.contains("PUEBLA") {
                                            break
                                        }
                                        localityParts.append(nextPart)
                                    }
                                    locality = localityParts.joined(separator: " ")
                                    break
                                } else if part == "LA" && i + 1 < addressParts.count {
                                    // Get all parts after "LA" until we hit a number or municipality
                                    var localityParts: [String] = [part]
                                    for j in (i + 1)..<addressParts.count {
                                        let nextPart = addressParts[j]
                                        // Stop if we hit a number (postal code) or municipality
                                        if nextPart.range(of: #"^\d+$"#, options: .regularExpression) != nil ||
                                           nextPart.contains("MONTERREY") || nextPart.contains("CDMX") ||
                                           nextPart.contains("GUADALAJARA") || nextPart.contains("PUEBLA") {
                                            break
                                        }
                                        localityParts.append(nextPart)
                                    }
                                    locality = localityParts.joined(separator: " ")
                                    break
                                }
                            }
                        }
                        break
                    }
                }
            }
            
            // Extract electoral section information
            if electoralSection.isEmpty {
                for keyword in electoralKeywords {
                    if cleanLine.contains(keyword) {
                        // Look for numbers after electoral keywords
                        let nextLines = lines.suffix(from: index).prefix(3)
                        for nextLine in nextLines {
                            let numbers = nextLine.components(separatedBy: CharacterSet.decimalDigits.inverted)
                                .filter { !$0.isEmpty }
                            if !numbers.isEmpty {
                                electoralSection = numbers.joined(separator: " ")
                                break
                            }
                        }
                        if !electoralSection.isEmpty { break }
                    }
                }
            }
            
            // Extract location information
            for keyword in locationKeywords {
                if cleanLine.contains(keyword) {
                    let nextLines = lines.suffix(from: index).prefix(2)
                    for nextLine in nextLines {
                        let cleanNextLine = nextLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanNextLine.isEmpty && !cleanNextLine.contains(keyword) {
                            if keyword.contains("LOCALIDAD") && locality.isEmpty {
                                locality = cleanNextLine
                            } else if keyword.contains("MUNICIPIO") && municipality.isEmpty {
                                municipality = cleanNextLine
                            } else if keyword.contains("ESTADO") && state.isEmpty {
                                state = cleanNextLine
                            }
                            break
                        }
                    }
                }
            }
        }
        
        // Extract document number from back side (10-digit number)
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Look for 10-digit number pattern
            if let docMatch = cleanLine.range(of: #"[0-9]{10}"#, options: .regularExpression) {
                documentNumber = String(cleanLine[docMatch])
                break
            }
        }
        
        // Look for QR code patterns or additional data
        let qrKeywords = ["QR", "CÓDIGO", "VERIFICAR", "VIGENCIA"]
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            for keyword in qrKeywords {
                if cleanLine.contains(keyword) {
                    additionalInfo += cleanLine + " "
                }
            }
        }
        
        return OCRResults(
            firstName: "",
            lastName: "",
            middleName: "",
            dateOfBirth: "",
            documentNumber: documentNumber,
            nationality: "",
            address: address,
            occupation: "",
            incomeSource: "",
            curp: "",
            sex: "",
            electoralSection: electoralSection,
            locality: locality,
            municipality: municipality,
            state: state,
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
