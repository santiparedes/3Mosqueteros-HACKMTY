import WidgetKit
import SwiftUI

struct NepWidgetView: View {
    var entry: NepWidgetProvider.Entry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
            
            VStack(spacing: 8) {
                // Icon
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                // Title
                Text("NepPay")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                // Status
                Text(entry.connectionStatus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .widgetURL(URL(string: "quantumwallet://tap-to-send"))
    }
}


#Preview(as: .systemSmall) {
    NepWidget()
} timeline: {
    NepWidgetEntry(
        date: .now,
        isAuthenticated: false,
        connectionStatus: "Listo",
        lastTransaction: nil
    )
}
