import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        print("🚀 SupabaseConfig: Initializing Supabase client...")
        
        // Validate configuration first
        do {
            try AppConfig.validate()
            print("✅ SupabaseConfig: Configuration validation passed")
        } catch {
            print("⚠️ SupabaseConfig: Configuration Warning - \(error.localizedDescription)")
            print("Please update AppConfig.swift with your actual Supabase credentials")
        }
        
        // Initialize Supabase client
        let url = AppConfig.Supabase.url
        let anonKey = AppConfig.Supabase.anonKey
        
        print("📍 SupabaseConfig: URL - \(url)")
        print("🔑 SupabaseConfig: Anon Key - \(anonKey.prefix(20))...")
        
        guard let supabaseURL = URL(string: url) else {
            fatalError("Invalid Supabase URL: \(url)")
        }
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey
        )
        
        print("✅ SupabaseConfig: Client initialized successfully")
    }
}
