import AppIntents
import LocalAuthentication

struct SendMoneyIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Money"
    static var description = IntentDescription("Send money using Tap-to-Send with Face ID authentication")
    
    @Parameter(title: "Amount")
    var amount: Int
    
    init(amount: Int) {
        self.amount = amount
    }
    
    init() {
        self.amount = 10
    }
    
    func perform() async throws -> some IntentResult {
        // Authenticate with Face ID
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw IntentError.authenticationNotAvailable
        }
        
        let reason = "Autenticar para enviar $\(amount) MXN"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Update shared data
                let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
                sharedDefaults?.set(true, forKey: "isAuthenticated")
                sharedDefaults?.set("Enviando $\(amount) MXN...", forKey: "connectionStatus")
                sharedDefaults?.set("$\(amount).00 MXN", forKey: "lastTransaction")
                sharedDefaults?.set(amount, forKey: "selectedAmount")
                sharedDefaults?.set("MXN", forKey: "selectedCurrency")
                
                // Open app to complete transaction
                return .result(opensIntent: OpenAppIntent())
            } else {
                throw IntentError.authenticationFailed
            }
        } catch {
            throw IntentError.authenticationFailed
        }
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Open the main app")
    
    func perform() async throws -> some IntentResult {
        // This will open the main app
        return .result()
    }
}

enum IntentError: Error, LocalizedError {
    case authenticationNotAvailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationNotAvailable:
            return "Biometric authentication is not available"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
