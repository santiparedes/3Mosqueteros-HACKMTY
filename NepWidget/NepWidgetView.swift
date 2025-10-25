import WidgetKit
import SwiftUI

struct NepWidgetView: View {
    var entry: NepWidgetProvider.Entry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.blue.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                // Icon
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                // Title
                Text("Tap to Send")
                    .font(.system(size: 12, weight: .semibold))
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

struct NepWidgetMediumView: View {
    var entry: NepWidgetProvider.Entry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.blue.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            HStack(spacing: 16) {
                // Left side - Main action
                VStack(spacing: 8) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Tap to Send")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(entry.connectionStatus)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Amount presets
                VStack(spacing: 6) {
                    AmountPresetButton(amount: 10)
                    AmountPresetButton(amount: 25)
                    AmountPresetButton(amount: 50)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .widgetURL(URL(string: "quantumwallet://tap-to-send"))
    }
}

struct NepWidgetLargeView: View {
    var entry: NepWidgetProvider.Entry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.blue.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Tap to Send")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(entry.isAuthenticated ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                }
                
                // Status
                Text(entry.connectionStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // Amount presets grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    AmountPresetButton(amount: 10)
                    AmountPresetButton(amount: 25)
                    AmountPresetButton(amount: 50)
                    AmountPresetButton(amount: 100)
                    AmountPresetButton(amount: 200)
                    AmountPresetButton(amount: 500)
                }
                
                // Last transaction
                if let lastTransaction = entry.lastTransaction {
                    Text("Last: \(lastTransaction)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
        }
        .widgetURL(URL(string: "quantumwallet://tap-to-send"))
    }
}

struct AmountPresetButton: View {
    let amount: Int
    
    var body: some View {
        Button(intent: SendMoneyIntent(amount: amount)) {
            Text("$\(amount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview(as: .systemSmall) {
    NepWidget()
} timeline: {
    NepWidgetEntry(
        date: .now,
        isAuthenticated: false,
        connectionStatus: "Ready",
        lastTransaction: nil
    )
}

#Preview(as: .systemMedium) {
    NepWidgetMedium()
} timeline: {
    NepWidgetEntry(
        date: .now,
        isAuthenticated: true,
        connectionStatus: "Connected",
        lastTransaction: nil
    )
}

#Preview(as: .systemLarge) {
    NepWidgetLarge()
} timeline: {
    NepWidgetEntry(
        date: .now,
        isAuthenticated: true,
        connectionStatus: "Connected",
        lastTransaction: "$25.00"
    )
}
