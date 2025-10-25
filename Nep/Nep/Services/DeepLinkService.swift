import Foundation
import SwiftUI

// MARK: - Deep Link Service
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()
    
    @Published var pendingDeepLink: DeepLink?
    @Published var showTapToSend = false
    @Published var showPaymentRequest = false
    
    private init() {}
    
    // MARK: - URL Handling
    
    func handleURL(_ url: URL) {
        print("Handling deep link: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("Invalid URL components")
            return
        }
        
        // Handle quantumwallet:// scheme
        if url.scheme == "quantumwallet" {
            handleCustomScheme(components)
        }
        // Handle universal links (https://quantumwallet.app)
        else if url.host == "quantumwallet.app" {
            handleUniversalLink(components)
        }
    }
    
    private func handleCustomScheme(_ components: URLComponents) {
        guard let host = components.host else { return }
        
        switch host {
        case "send":
            handleSendMoney(components)
        case "request":
            handleRequestMoney(components)
        case "tap-to-send":
            handleTapToSend(components)
        default:
            print("Unknown custom scheme host: \(host)")
        }
    }
    
    private func handleUniversalLink(_ components: URLComponents) {
        let pathComponents = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard !pathComponents.isEmpty else { return }
        
        switch pathComponents[0] {
        case "send":
            handleSendMoney(components)
        case "request":
            handleRequestMoney(components)
        case "tap-to-send":
            handleTapToSend(components)
        default:
            print("Unknown universal link path: \(pathComponents[0])")
        }
    }
    
    // MARK: - Specific Handlers
    
    private func handleSendMoney(_ components: URLComponents) {
        let queryItems = components.queryItems ?? []
        
        var amount: Double = 0.0
        var currency: String = "USD"
        var recipient: String = ""
        var message: String = ""
        
        for item in queryItems {
            switch item.name {
            case "amount":
                if let value = item.value {
                    amount = Double(value) ?? 0.0
                }
            case "currency":
                currency = item.value ?? "USD"
            case "recipient":
                recipient = item.value ?? ""
            case "message":
                message = item.value ?? ""
            default:
                break
            }
        }
        
        let deepLink = DeepLink(
            type: .sendMoney,
            amount: amount,
            currency: currency,
            recipient: recipient,
            message: message
        )
        
        DispatchQueue.main.async {
            self.pendingDeepLink = deepLink
            self.showTapToSend = true
        }
    }
    
    private func handleRequestMoney(_ components: URLComponents) {
        let queryItems = components.queryItems ?? []
        
        var amount: Double = 0.0
        var currency: String = "USD"
        var requester: String = ""
        var message: String = ""
        
        for item in queryItems {
            switch item.name {
            case "amount":
                if let value = item.value {
                    amount = Double(value) ?? 0.0
                }
            case "currency":
                currency = item.value ?? "USD"
            case "requester":
                requester = item.value ?? ""
            case "message":
                message = item.value ?? ""
            default:
                break
            }
        }
        
        let deepLink = DeepLink(
            type: .requestMoney,
            amount: amount,
            currency: currency,
            recipient: requester,
            message: message
        )
        
        DispatchQueue.main.async {
            self.pendingDeepLink = deepLink
            self.showPaymentRequest = true
        }
    }
    
    private func handleTapToSend(_ components: URLComponents) {
        let queryItems = components.queryItems ?? []
        
        var amount: Double = 0.0
        var currency: String = "USD"
        var message: String = ""
        
        for item in queryItems {
            switch item.name {
            case "amount":
                if let value = item.value {
                    amount = Double(value) ?? 0.0
                }
            case "currency":
                currency = item.value ?? "USD"
            case "message":
                message = item.value ?? ""
            default:
                break
            }
        }
        
        let deepLink = DeepLink(
            type: .tapToSend,
            amount: amount,
            currency: currency,
            recipient: "",
            message: message
        )
        
        DispatchQueue.main.async {
            self.pendingDeepLink = deepLink
            self.showTapToSend = true
        }
    }
    
    // MARK: - URL Generation
    
    func generateSendMoneyURL(amount: Double, currency: String = "USD", recipient: String = "", message: String = "") -> URL? {
        var components = URLComponents()
        components.scheme = "quantumwallet"
        components.host = "send"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
        queryItems.append(URLQueryItem(name: "currency", value: currency))
        
        if !recipient.isEmpty {
            queryItems.append(URLQueryItem(name: "recipient", value: recipient))
        }
        
        if !message.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: message))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    func generateRequestMoneyURL(amount: Double, currency: String = "USD", requester: String = "", message: String = "") -> URL? {
        var components = URLComponents()
        components.scheme = "quantumwallet"
        components.host = "request"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
        queryItems.append(URLQueryItem(name: "currency", value: currency))
        
        if !requester.isEmpty {
            queryItems.append(URLQueryItem(name: "requester", value: requester))
        }
        
        if !message.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: message))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    func generateTapToSendURL(amount: Double, currency: String = "USD", message: String = "") -> URL? {
        var components = URLComponents()
        components.scheme = "quantumwallet"
        components.host = "tap-to-send"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
        queryItems.append(URLQueryItem(name: "currency", value: currency))
        
        if !message.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: message))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    func generateUniversalLink(type: DeepLinkType, amount: Double, currency: String = "USD", recipient: String = "", message: String = "") -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "quantumwallet.app"
        
        switch type {
        case .sendMoney:
            components.path = "/send"
        case .requestMoney:
            components.path = "/request"
        case .tapToSend:
            components.path = "/tap-to-send"
        }
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "amount", value: String(amount)))
        queryItems.append(URLQueryItem(name: "currency", value: currency))
        
        if !recipient.isEmpty {
            queryItems.append(URLQueryItem(name: "recipient", value: recipient))
        }
        
        if !message.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: message))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    // MARK: - Share Functionality
    
    func sharePaymentRequest(amount: Double, currency: String = "USD", message: String = "") {
        guard let url = generateTapToSendURL(amount: amount, currency: currency, message: message) else {
            print("Failed to generate share URL")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [
                "Send me \(formatCurrency(amount, currency: currency)) via Quantum Wallet",
                url
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}

// MARK: - Deep Link Models
struct DeepLink {
    let type: DeepLinkType
    let amount: Double
    let currency: String
    let recipient: String
    let message: String
}

enum DeepLinkType {
    case sendMoney
    case requestMoney
    case tapToSend
}
