import Foundation

struct APIConfig {
    // MARK: - API Keys
    // TODO: Replace these with your actual API keys
    static let geminiAPIKey = "" // Disabled for testing
    static let elevenLabsAPIKey = "" // Disabled for testing
    
    // MARK: - API URLs
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    static let elevenLabsBaseURL = "https://api.elevenlabs.io/v1"
    
    // MARK: - ElevenLabs Voice Settings
    static let defaultVoiceId = "pNInz6obpgDQGcFmaJgB" // Adam voice (multilingual)
    static let spanishVoiceId = "pNInz6obpgDQGcFmaJgB" // You can change this to a Spanish-specific voice
    
    // MARK: - Gemini Model Settings
    static let geminiModel = "gemini-pro"
    static let maxTokens = 1024
    static let temperature = 0.7
    
    // MARK: - Validation
    static var isGeminiConfigured: Bool {
        return !geminiAPIKey.isEmpty && geminiAPIKey != "YOUR_ACTUAL_GEMINI_API_KEY"
    }
    
    static var isElevenLabsConfigured: Bool {
        return !elevenLabsAPIKey.isEmpty && elevenLabsAPIKey != "YOUR_ACTUAL_ELEVENLABS_API_KEY"
    }
    
    static var isFullyConfigured: Bool {
        return isGeminiConfigured && isElevenLabsConfigured
    }
}
