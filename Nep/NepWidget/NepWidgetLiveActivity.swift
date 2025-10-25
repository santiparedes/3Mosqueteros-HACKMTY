//
//  NepWidgetLiveActivity.swift
//  NepWidget
//
//  Created by Santiago Paredes on 25/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NepWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NepWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NepWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension NepWidgetAttributes {
    fileprivate static var preview: NepWidgetAttributes {
        NepWidgetAttributes(name: "World")
    }
}

extension NepWidgetAttributes.ContentState {
    fileprivate static var smiley: NepWidgetAttributes.ContentState {
        NepWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NepWidgetAttributes.ContentState {
         NepWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NepWidgetAttributes.preview) {
   NepWidgetLiveActivity()
} contentStates: {
    NepWidgetAttributes.ContentState.smiley
    NepWidgetAttributes.ContentState.starEyes
}
