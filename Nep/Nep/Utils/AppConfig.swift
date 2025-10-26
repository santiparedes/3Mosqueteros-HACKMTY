import Foundation

struct AppConfig {
    struct Supabase {
        static let url = "https://aaseaqeolqpjfqkpsuyd.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc2VhcWVvbHFwamZxa3BzdXlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyNDgsImV4cCI6MjA3NTExODI0OH0.FKekZn3VVS1I7FFQFFlwUZ2sTMp50d1X7G3sxFac3ug"
    }
    
    struct API {
        static let baseURL = "http://localhost:5000"
        static let nessieBaseURL = "http://api.nessieisreal.com"
        static let nessieAPIKey = "YOUR_NESSIE_API_KEY" // TODO: Replace with your Nessie API key
        static let creditServiceBaseURL = "http://localhost:8002"
    }
    
    struct AI {
        static let geminiAPIKey = "YOUR_GEMINI_API_KEY" // TODO: Replace with your Gemini API key
        static let elevenLabsAPIKey = "YOUR_ELEVENLABS_API_KEY" // TODO: Replace with your ElevenLabs API key
    }
    
    struct Features {
        static let healthKitEnabled = true
        static let notificationEnabled = true
        static let quantumWalletEnabled = true
        static let biometricAuthEnabled = true
    }
    
    enum ConfigError: Error, LocalizedError {
        case missingSupabaseURL
        case missingSupabaseAnonKey
        case missingNessieAPIKey
        case missingGeminiAPIKey
        case missingElevenLabsAPIKey
        
        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL: return "Supabase URL is not configured in AppConfig.swift"
            case .missingSupabaseAnonKey: return "Supabase Anon Key is not configured in AppConfig.swift"
            case .missingNessieAPIKey: return "Nessie API Key is not configured in AppConfig.swift"
            case .missingGeminiAPIKey: return "Gemini API Key is not configured in AppConfig.swift"
            case .missingElevenLabsAPIKey: return "ElevenLabs API Key is not configured in AppConfig.swift"
            }
        }
    }
    
    static func validate() throws {
        if Supabase.url.contains("your-project-id") { throw ConfigError.missingSupabaseURL }
        if Supabase.anonKey.contains("your-anon-key-here") { throw ConfigError.missingSupabaseAnonKey }
        if API.nessieAPIKey.contains("YOUR_NESSIE_API_KEY") { throw ConfigError.missingNessieAPIKey }
        // Optional keys will show warnings but not fatal errors
        if AI.geminiAPIKey.contains("YOUR_GEMINI_API_KEY") { print("⚠️ Warning: Gemini API key not configured") }
        if AI.elevenLabsAPIKey.contains("YOUR_ELEVENLABS_API_KEY") { print("⚠️ Warning: ElevenLabs API key not configured") }
    }
}
