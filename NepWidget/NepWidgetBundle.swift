import WidgetKit
import SwiftUI
import AppIntents

@main
struct NepWidgetBundle: WidgetBundle {
    var body: some Widget {
        NepWidget()
        NepWidgetMedium()
        NepWidgetLarge()
    }
}

// Register App Intents
extension NepWidgetBundle {
    static func registerIntents() {
        SendMoneyIntent.register()
    }
}
