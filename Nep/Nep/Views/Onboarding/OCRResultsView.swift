import SwiftUI

struct OCRResultsView: View {
    @StateObject private var elevenLabsService = ElevenLabsService.shared
    @StateObject private var geminiService = GeminiAIService.shared
    @State private var currentStep = 0
    @State private var userInput = ""
    @State private var isEditing = false
    @State private var showVoiceInterface = false
    @State private var updatedResults: OCRResults
    @State private var ineAnalysis: INEAnalysis?
    @State private var showAnalysis = false
    let results: OCRResults
    let onComplete: () -> Void
    
    init(results: OCRResults, onComplete: @escaping () -> Void) {
        self.results = results
        self.onComplete = onComplete
        self._updatedResults = State(initialValue: results)
    }
    
    var body: some View {
        ZStack {
            // Background
            GrainyGradientView.welcomeGradient()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Verificación de Datos")
                        .font(.custom("BrunoACESC-regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        onComplete()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        ProgressIndicator(currentStep: currentStep, totalSteps: 4)
                            .padding(.horizontal, 20)
                        
                        // Current step content
                        switch currentStep {
                        case 0:
                            INEDataConfirmationView(
                                results: updatedResults,
                                analysis: ineAnalysis,
                                onEdit: { field, newValue in
                                    updateField(field, with: newValue)
                                },
                                showAnalysis: $showAnalysis
                            )
                        case 1:
                            VoiceConversationView(
                                elevenLabsService: elevenLabsService,
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        currentStep += 1
                                    }
                                }
                            )
                        case 2:
                            AdditionalInfoView(
                                results: $updatedResults,
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        currentStep += 1
                                    }
                                }
                            )
                        case 3:
                            FinalConfirmationView(
                                results: updatedResults,
                                onComplete: onComplete
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            startVoiceConversation()
        }
    }
    
    private func startVoiceConversation() {
        Task {
            // Update ElevenLabs with current results
            elevenLabsService.updateOCRResults(updatedResults)
            
            // Analyze INE document with Gemini
            ineAnalysis = await geminiService.analyzeINEDocument(updatedResults)
            
            // Start Gemini-powered conversation
            await elevenLabsService.startOnboardingConversation(ocrResults: updatedResults)
        }
    }
    
    private func updateField(_ field: DataField, with value: String) {
        updatedResults = createUpdatedResults(field: field, value: value)
    }
    
    private func createUpdatedResults(field: DataField, value: String) -> OCRResults {
        return OCRResults(
            firstName: field == .firstName ? value : updatedResults.firstName,
            lastName: field == .lastName ? value : updatedResults.lastName,
            middleName: field == .middleName ? value : updatedResults.middleName,
            dateOfBirth: field == .dateOfBirth ? value : updatedResults.dateOfBirth,
            documentNumber: field == .documentNumber ? value : updatedResults.documentNumber,
            nationality: field == .nationality ? value : updatedResults.nationality,
            address: field == .address ? value : updatedResults.address,
            occupation: field == .occupation ? value : updatedResults.occupation,
            incomeSource: field == .incomeSource ? value : updatedResults.incomeSource,
            curp: field == .curp ? value : updatedResults.curp,
            sex: field == .sex ? value : updatedResults.sex,
            electoralSection: field == .electoralSection ? value : updatedResults.electoralSection,
            locality: field == .locality ? value : updatedResults.locality,
            municipality: field == .municipality ? value : updatedResults.municipality,
            state: field == .state ? value : updatedResults.state,
            expirationDate: field == .expirationDate ? value : updatedResults.expirationDate,
            issueDate: field == .issueDate ? value : updatedResults.issueDate
        )
    }
}

enum DataField {
    case firstName, lastName, middleName, dateOfBirth, documentNumber, nationality, address, occupation, incomeSource
    case curp, sex, electoralSection, locality, municipality, state, expirationDate, issueDate
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.nepBlue : Color.white.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.vertical, 20)
    }
}

struct DataConfirmationView: View {
    let results: OCRResults
    let onEdit: (DataField, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Datos Detectados")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Revisa y corrige los datos extraídos de tu identificación:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 16) {
                DataFieldView(
                    title: "Nombre Completo",
                    value: results.fullName,
                    onEdit: { newValue in
                        handleNameEdit(newValue)
                    }
                )
                
                DataFieldView(
                    title: "Fecha de Nacimiento",
                    value: results.dateOfBirth,
                    onEdit: { onEdit(.dateOfBirth, $0) }
                )
                
                DataFieldView(
                    title: "Número de Documento",
                    value: results.documentNumber,
                    onEdit: { onEdit(.documentNumber, $0) }
                )
                
                DataFieldView(
                    title: "Nacionalidad",
                    value: results.nationality,
                    onEdit: { onEdit(.nationality, $0) }
                )
                
                DataFieldView(
                    title: "Dirección",
                    value: results.address,
                    onEdit: { onEdit(.address, $0) }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func handleNameEdit(_ newValue: String) {
        let components = newValue.components(separatedBy: " ")
        onEdit(.firstName, components.first ?? "")
        if components.count > 1 {
            onEdit(.lastName, components.last ?? "")
        }
    }
}

struct DataFieldView: View {
    let title: String
    let value: String
    let onEdit: (String) -> Void
    
    @State private var isEditing = false
    @State private var editedValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                if isEditing {
                    TextField("", text: $editedValue)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .onSubmit {
                            onEdit(editedValue)
                            isEditing = false
                        }
                } else {
                    Text(value.isEmpty ? "No detectado" : value)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(value.isEmpty ? .white.opacity(0.5) : .white)
                }
                
                Spacer()
                
                Button(action: {
                    if isEditing {
                        onEdit(editedValue)
                    } else {
                        editedValue = value
                    }
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nepBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

struct VoiceConversationView: View {
    @ObservedObject var elevenLabsService: ElevenLabsService
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Voice interface
            VStack(spacing: 20) {
                Text("Conversación con Asistente")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Voice visualization
                ZStack {
                    Circle()
                        .fill(Color.nepBlue.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    if elevenLabsService.isSpeaking {
                        Circle()
                            .fill(Color.nepBlue)
                            .frame(width: 100, height: 100)
                            .scaleEffect(elevenLabsService.isSpeaking ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: elevenLabsService.isSpeaking)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.nepBlue)
                    }
                }
                
                Text(elevenLabsService.currentMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Voice controls
            HStack(spacing: 20) {
                Button(action: {
                    if elevenLabsService.isListening {
                        elevenLabsService.stopListening()
                    } else {
                        Task {
                            try? await elevenLabsService.startListening()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: elevenLabsService.isListening ? "stop.fill" : "mic.fill")
                        Text(elevenLabsService.isListening ? "Detener" : "Hablar")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(elevenLabsService.isListening ? Color.red : Color.nepBlue)
                    .cornerRadius(25)
                }
                
                Button(action: onNext) {
                    HStack {
                        Text("Continuar")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.nepLightBlue)
                    .cornerRadius(25)
                }
            }
        }
    }
}

struct AdditionalInfoView: View {
    @Binding var results: OCRResults
    let onNext: () -> Void
    
    @State private var occupation = ""
    @State private var incomeSource = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Información Adicional")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Completa la siguiente información:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ocupación")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Ej: Ingeniero, Doctor, Estudiante...", text: $occupation)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fuente Principal de Ingreso")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Ej: Salario, Negocio propio, Inversiones...", text: $incomeSource)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            Button(action: {
                results = OCRResults(
                    firstName: results.firstName,
                    lastName: results.lastName,
                    middleName: results.middleName,
                    dateOfBirth: results.dateOfBirth,
                    documentNumber: results.documentNumber,
                    nationality: results.nationality,
                    address: results.address,
                    occupation: occupation,
                    incomeSource: incomeSource,
                    curp: results.curp,
                    sex: results.sex,
                    electoralSection: results.electoralSection,
                    locality: results.locality,
                    municipality: results.municipality,
                    state: results.state,
                    expirationDate: results.expirationDate,
                    issueDate: results.issueDate
                )
                onNext()
            }) {
                HStack {
                    Text("Continuar")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.nepBlue)
                .cornerRadius(25)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct FinalConfirmationView: View {
    let results: OCRResults
    let onComplete: () -> Void
    
    @StateObject private var onboardingService = OnboardingService.shared
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("¡Verificación Completa!")
                .font(.custom("BrunoACESC-regular", size: 32))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Todos tus datos han sido verificados correctamente")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                Text("Resumen de tu perfil:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    SummaryRow(title: "Nombre", value: results.fullName)
                    SummaryRow(title: "Fecha de Nacimiento", value: results.dateOfBirth)
                    SummaryRow(title: "Documento", value: results.documentNumber)
                    SummaryRow(title: "Ocupación", value: results.occupation)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            
            Button(action: {
                submitOnboardingData()
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Finalizar Registro")
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.nepBlue, Color.nepLightBlue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
            }
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.7 : 1.0)
        }
        .padding(20)
        .alert("Error", isPresented: $showError) {
            Button("Reintentar") {
                submitOnboardingData()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitOnboardingData() {
        isSubmitting = true
        
        Task {
            do {
                let userId = UUID().uuidString // In real app, get from user session
                let response = try await onboardingService.saveOnboardingData(results, userId: userId)
                
                await MainActor.run {
                    isSubmitting = false
                    OnboardingLogger.shared.logEvent(.dataSubmitted)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                    OnboardingLogger.shared.logEvent(.errorOccurred(error: error.localizedDescription))
                }
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct INEDataConfirmationView: View {
    let results: OCRResults
    let analysis: INEAnalysis?
    let onEdit: (DataField, String) -> Void
    @Binding var showAnalysis: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with INE validation status
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Datos de INE Detectados")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let analysis = analysis {
                        HStack(spacing: 12) {
                            Image(systemName: analysis.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(analysis.isValid ? .green : .orange)
                                .font(.system(size: 20))
                            
                            Text(analysis.isValid ? "INE Válida" : "Requiere Verificación")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(analysis.isValid ? .green : .orange)
                            
                            Text("Confianza: \(Int(analysis.confidence * 100))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                if let analysis = analysis {
                    Button(action: {
                        showAnalysis = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.nepBlue)
                    }
                }
            }
            
            Text("Revisa y corrige los datos extraídos de tu INE:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // INE-specific data fields
            VStack(spacing: 16) {
                // Personal Information Section
                PersonalInfoSection(results: results, onEdit: onEdit, handleNameEdit: handleNameEdit)
                
                // Location Information Section
                LocationInfoSection(results: results, onEdit: onEdit)
                
                // Document Information Section
                DocumentInfoSection(results: results, onEdit: onEdit)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showAnalysis) {
            if let analysis = analysis {
                INEAnalysisView(analysis: analysis)
            }
        }
    }
    
    private func handleNameEdit(_ newValue: String) {
        let components = newValue.components(separatedBy: " ")
        onEdit(.firstName, components.first ?? "")
        if components.count > 1 {
            onEdit(.lastName, components.last ?? "")
        }
        if components.count > 2 {
            onEdit(.middleName, components[1])
        }
    }
}

struct INEDataFieldView: View {
    let title: String
    let value: String
    let onEdit: (String) -> Void
    
    @State private var isEditing = false
    @State private var editedValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                if isEditing {
                    TextField("", text: $editedValue)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .onSubmit {
                            onEdit(editedValue)
                            isEditing = false
                        }
                } else {
                    Text(value.isEmpty ? "No detectado" : value)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(value.isEmpty ? .white.opacity(0.5) : .white)
                }
                
                Spacer()
                
                Button(action: {
                    if isEditing {
                        onEdit(editedValue)
                    } else {
                        editedValue = value
                    }
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.nepBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

struct INEAnalysisView: View {
    let analysis: INEAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nepDarkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Analysis Header
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: analysis.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(analysis.isValid ? .green : .orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(analysis.isValid ? "INE Válida" : "Requiere Atención")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Confianza: \(Int(analysis.confidence * 100))%")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Missing Fields
                        if !analysis.missingFields.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Campos Faltantes")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(analysis.missingFields, id: \.self) { field in
                                    HStack {
                                        Image(systemName: "exclamationmark.circle")
                                            .foregroundColor(.orange)
                                        Text(field)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                }
                            }
                        }
                        
                        // Suggestions
                        if !analysis.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sugerencias")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(analysis.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top) {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.nepBlue)
                                        Text(suggestion)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.nepBlue.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Análisis de INE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.nepBlue)
                }
            }
        }
    }
}

// MARK: - Section Components
struct PersonalInfoSection: View {
    let results: OCRResults
    let onEdit: (DataField, String) -> Void
    let handleNameEdit: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            INEDataFieldView(
                title: "Nombre Completo",
                value: results.fullName,
                onEdit: handleNameEdit
            )
            
            INEDataFieldView(
                title: "CURP",
                value: results.curp,
                onEdit: { onEdit(.curp, $0) }
            )
            
            INEDataFieldView(
                title: "Fecha de Nacimiento",
                value: results.dateOfBirth,
                onEdit: { onEdit(.dateOfBirth, $0) }
            )
            
            INEDataFieldView(
                title: "Número de INE",
                value: results.documentNumber,
                onEdit: { onEdit(.documentNumber, $0) }
            )
        }
    }
}

struct LocationInfoSection: View {
    let results: OCRResults
    let onEdit: (DataField, String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            INEDataFieldView(
                title: "Estado",
                value: results.state,
                onEdit: { onEdit(.state, $0) }
            )
            
            INEDataFieldView(
                title: "Municipio",
                value: results.municipality,
                onEdit: { onEdit(.municipality, $0) }
            )
            
            INEDataFieldView(
                title: "Localidad",
                value: results.locality,
                onEdit: { onEdit(.locality, $0) }
            )
            
            INEDataFieldView(
                title: "Sección Electoral",
                value: results.electoralSection,
                onEdit: { onEdit(.electoralSection, $0) }
            )
        }
    }
}

struct DocumentInfoSection: View {
    let results: OCRResults
    let onEdit: (DataField, String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            INEDataFieldView(
                title: "Fecha de Emisión",
                value: results.issueDate,
                onEdit: { onEdit(.issueDate, $0) }
            )
            
            INEDataFieldView(
                title: "Fecha de Vencimiento",
                value: results.expirationDate,
                onEdit: { onEdit(.expirationDate, $0) }
            )
        }
    }
}

#Preview {
    OCRResultsView(
        results: OCRResults.empty,
        onComplete: {}
    )
    .preferredColorScheme(.dark)
}
