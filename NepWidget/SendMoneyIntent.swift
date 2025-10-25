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
        
        let reason = "Authenticate to send $\(amount)"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                // Update shared data
                let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
                sharedDefaults?.set(true, forKey: "isAuthenticated")
                sharedDefaults?.set("Sending $\(amount)...", forKey: "connectionStatus")
                sharedDefaults?.set("$\(amount).00", forKey: "lastTransaction")
                
                // Open app to complete transaction
                return .result()
            } else {
                throw IntentError.authenticationFailed
            }
        } catch {
            throw IntentError.authenticationFailed
        }
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
