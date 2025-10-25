import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .tag(0)
                    
                    QuantumBankingView()
                        .tabItem {
                            Image(systemName: "shield.lefthalf.filled")
                            Text("Quantum")
                        }
                        .tag(1)
                    
                    CardDetailsView()
                        .tabItem {
                            Image(systemName: "asterisk")
                            Text("Card")
                        }
                        .tag(2)
                    
                    AddView()
                        .tabItem {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .tag(3)
                    
                    MenuView()
                        .tabItem {
                            Image(systemName: "ellipsis")
                            Text("Menu")
                        }
                        .tag(4)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                        .tag(5)
                }
                .accentColor(.nepBlue)
            } else {
                WelcomeView()
                    .onAppear {
                        // Simulate login after 3 seconds for demo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isLoggedIn = true
                        }
                    }
            }
        }
    }
}

struct AddView: View {
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Add Money")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                Text("Choose how you'd like to add money to your account")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nepTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 16) {
                    AddOptionButton(
                        title: "Bank Transfer",
                        subtitle: "Transfer from your bank account",
                        icon: "arrow.down.circle"
                    )
                    
                    AddOptionButton(
                        title: "Credit Card",
                        subtitle: "Add money using a credit card",
                        icon: "creditcard"
                    )
                    
                    AddOptionButton(
                        title: "Cash Deposit",
                        subtitle: "Deposit cash at a partner location",
                        icon: "banknote"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct AddOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.nepBlue)
                    .frame(width: 40, height: 40)
                    .background(Color.nepBlue.opacity(0.1))
                    .cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.nepTextLight)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct MenuView: View {
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Menu")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.nepTextLight)
                
                VStack(spacing: 12) {
                    MenuOptionButton(
                        title: "Settings",
                        icon: "gearshape"
                    )
                    
                    MenuOptionButton(
                        title: "Help & Support",
                        icon: "questionmark.circle"
                    )
                    
                    MenuOptionButton(
                        title: "Security",
                        icon: "shield"
                    )
                    
                    MenuOptionButton(
                        title: "Notifications",
                        icon: "bell"
                    )
                    
                    MenuOptionButton(
                        title: "About",
                        icon: "info.circle"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct MenuOptionButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.nepBlue)
                    .frame(width: 40, height: 40)
                    .background(Color.nepBlue.opacity(0.1))
                    .cornerRadius(20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nepTextLight)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.nepDarkBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.nepBlue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("John Doe")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.nepTextLight)
                    
                    Text("john.doe@example.com")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.nepTextSecondary)
                }
                .padding(.top, 50)
                
                // Profile options
                VStack(spacing: 12) {
                    ProfileOptionButton(
                        title: "Personal Information",
                        icon: "person.circle"
                    )
                    
                    ProfileOptionButton(
                        title: "Account Settings",
                        icon: "gear"
                    )
                    
                    ProfileOptionButton(
                        title: "Security Settings",
                        icon: "lock"
                    )
                    
                    ProfileOptionButton(
                        title: "Privacy Settings",
                        icon: "eye.slash"
                    )
                    
                    ProfileOptionButton(
                        title: "Sign Out",
                        icon: "arrow.right.square",
                        isDestructive: true
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

struct ProfileOptionButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .nepError : .nepBlue)
                    .frame(width: 40, height: 40)
                    .background((isDestructive ? Color.nepError : Color.nepBlue).opacity(0.1))
                    .cornerRadius(20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDestructive ? .nepError : .nepTextLight)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.nepTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.nepCardBackground.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    MainView()
}
