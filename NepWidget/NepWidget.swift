import WidgetKit
import SwiftUI

struct NepWidget: Widget {
    let kind: String = "NepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepWidgetProvider()) { entry in
            NepWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tap to Send")
        .description("Quick access to send money with Face ID")
        .supportedFamilies([.systemSmall])
    }
}

struct NepWidgetMedium: Widget {
    let kind: String = "NepWidgetMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepWidgetProvider()) { entry in
            NepWidgetMediumView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tap to Send Medium")
        .description("Quick access with amount presets")
        .supportedFamilies([.systemMedium])
    }
}

struct NepWidgetLarge: Widget {
    let kind: String = "NepWidgetLarge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepWidgetProvider()) { entry in
            NepWidgetLargeView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tap to Send Large")
        .description("Full interface with status and presets")
        .supportedFamilies([.systemLarge])
    }
}
