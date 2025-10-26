import SwiftUI

struct SupabaseTestView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var connectionStatus = "Testing..."
    @State private var isConnected = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isConnected ? .green : .red)
                
                Text("Supabase Connection")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(connectionStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if supabaseService.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
                
                Button("Test Connection") {
                    testConnection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(supabaseService.isLoading)
                
                if let errorMessage = supabaseService.errorMessage {
                    Text("Error: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Supabase Test")
            .onAppear {
                testConnection()
            }
        }
    }
    
    private func testConnection() {
        print("🔍 Testing Supabase connection...")
        print("📍 Supabase URL: \(AppConfig.Supabase.url)")
        print("🔑 Anon Key: \(AppConfig.Supabase.anonKey.prefix(20))...")
        
        Task {
            do {
                let connected = try await supabaseService.testConnection()
                print("✅ Supabase connection test result: \(connected)")
                
                await MainActor.run {
                    self.isConnected = connected
                    self.connectionStatus = connected ? "Connected successfully!" : "Connection failed"
                }
            } catch {
                print("❌ Supabase connection error: \(error)")
                print("📝 Error details: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.isConnected = false
                    self.connectionStatus = "Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    SupabaseTestView()
}
