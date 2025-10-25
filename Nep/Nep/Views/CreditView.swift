import SwiftUI

struct CreditView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "creditcard")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Credit View")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is a placeholder for the credit functionality")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Credit")
        }
    }
}

#Preview {
    CreditView()
}
