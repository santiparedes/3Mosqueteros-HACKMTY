import Foundation

// MARK: - Legacy Config (for backward compatibility)
enum Config {
    enum Error: Swift.Error {
        case missingKey, invalidValue, configurationNotSet
    }
    
    // MARK: - Supabase Configuration
    static var supabaseURL: String {
        return AppConfig.Supabase.url
    }
    
    static var supabaseAnonKey: String {
        return AppConfig.Supabase.anonKey
    }
    
    // MARK: - API Configuration
    static var apiBaseURL: String {
        return AppConfig.API.baseURL
    }
    
    static var nessieBaseURL: String {
        return AppConfig.API.nessieBaseURL
    }
    
    static var nessieAPIKey: String {
        return AppConfig.API.nessieAPIKey
    }
    
    // MARK: - AI Services Configuration
    static var geminiAPIKey: String {
        return AppConfig.AI.geminiAPIKey
    }
    
    static var elevenLabsAPIKey: String {
        return AppConfig.AI.elevenLabsAPIKey
    }
    
    // MARK: - Feature Flags
    static var healthKitEnabled: Bool {
        return AppConfig.Features.healthKitEnabled
    }
    
    static var notificationEnabled: Bool {
        return AppConfig.Features.notificationEnabled
    }
    
    static var quantumWalletEnabled: Bool {
        return AppConfig.Features.quantumWalletEnabled
    }
    
    static var biometricAuthEnabled: Bool {
        return AppConfig.Features.biometricAuthEnabled
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        // Fallback to Info.plist for any missing values
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }
        
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}