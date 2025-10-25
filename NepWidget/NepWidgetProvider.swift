import WidgetKit
import SwiftUI

struct NepWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NepWidgetEntry {
        NepWidgetEntry(
            date: Date(),
            isAuthenticated: false,
            connectionStatus: "Ready",
            lastTransaction: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NepWidgetEntry) -> ()) {
        let entry = NepWidgetEntry(
            date: Date(),
            isAuthenticated: false,
            connectionStatus: "Ready",
            lastTransaction: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NepWidgetEntry>) -> ()) {
        let currentDate = Date()
        
        // Get shared data from UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.tec.mx.nep")
        let isAuthenticated = sharedDefaults?.bool(forKey: "isAuthenticated") ?? false
        let connectionStatus = sharedDefaults?.string(forKey: "connectionStatus") ?? "Ready"
        
        let entry = NepWidgetEntry(
            date: currentDate,
            isAuthenticated: isAuthenticated,
            connectionStatus: connectionStatus,
            lastTransaction: nil
        )

        // Update every 30 seconds for testing
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct NepWidgetEntry: TimelineEntry {
    let date: Date
    let isAuthenticated: Bool
    let connectionStatus: String
    let lastTransaction: String?
}
