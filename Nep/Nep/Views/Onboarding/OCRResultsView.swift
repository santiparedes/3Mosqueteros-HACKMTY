import SwiftUI

struct OCRResultsView: View {
    @StateObject private var elevenLabsService = ElevenLabsService.shared
    @State private var currentStep = 0
    @State private var userInput = ""
    @State private var isEditing = false
    @State private var showVoiceInterface = false
    @State private var updatedResults: OCRResults
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
                            DataConfirmationView(
                                results: updatedResults,
                                onEdit: { field, newValue in
                                    updateField(field, with: newValue)
                                }
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
            incomeSource: field == .incomeSource ? value : updatedResults.incomeSource
        )
    }
}

enum DataField {
    case firstName, lastName, middleName, dateOfBirth, documentNumber, nationality, address, occupation, incomeSource
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
                    incomeSource: incomeSource
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

#Preview {
    OCRResultsView(
        results: OCRResults.empty,
        onComplete: {}
    )
    .preferredColorScheme(.dark)
}
