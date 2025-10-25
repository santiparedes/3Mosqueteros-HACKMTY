//
//  NepApp.swift
//  Nep
//
//  Created by Santiago Paredes on 24/10/25.
//

import SwiftUI

@main
struct NepApp: App {
    @StateObject private var deepLinkService = DeepLinkService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    deepLinkService.handleURL(url)
                }
                .fullScreenCover(isPresented: $deepLinkService.showTapToSend) {
                    if let deepLink = deepLinkService.pendingDeepLink {
                        TapToSendView()
                            .onAppear {
                                // Pre-populate the tap-to-send view with deep link data
                                if deepLink.amount > 0 {
                                    // This would be handled in the TapToSendView
                                }
                            }
                    } else {
                        TapToSendView()
                    }
                }
                .sheet(isPresented: $deepLinkService.showPaymentRequest) {
                    if let deepLink = deepLinkService.pendingDeepLink {
                        // Create a payment request view for deep links
                        DeepLinkPaymentRequestView(deepLink: deepLink)
                    }
                }
        }
    }
}
