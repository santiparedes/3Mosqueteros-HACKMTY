import Foundation
import LocalAuthentication
import SwiftUI

class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var isAvailable = false
    
    private init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAvailable = true
            biometricType = context.biometryType
        } else {
            isAvailable = false
            biometricType = .none
        }
    }
    
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, "Biometric authentication not available")
            return
        }
        
        let reason = "Authenticate to use Tap-to-Send"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    // Update shared data for widget
                    let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
                    sharedDefaults?.set(true, forKey: "isAuthenticated")
                    sharedDefaults?.set("Autenticado", forKey: "connectionStatus")
                    completion(true, nil)
                } else {
                    self?.isAuthenticated = false
                    let message = error?.localizedDescription ?? "Authentication failed"
                    completion(false, message)
                }
            }
        }
    }
    
    func logout() {
        isAuthenticated = false
        // Update shared data for widget
        let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
        sharedDefaults?.set(false, forKey: "isAuthenticated")
        sharedDefaults?.set("Listo", forKey: "connectionStatus")
    }
    
    var biometricTypeString: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "person.badge.key"
        }
    }
}
