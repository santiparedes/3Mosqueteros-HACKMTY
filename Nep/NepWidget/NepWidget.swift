import WidgetKit
import SwiftUI

struct NepWidget: Widget {
    let kind: String = "NepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepWidgetProvider()) { entry in
            NepWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("NepPay")
        .description("Quick access to send money with Face ID")
        .supportedFamilies([.systemSmall])
    }
}
