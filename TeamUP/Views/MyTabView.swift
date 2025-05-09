//
//  ContentView.swift
//  TeamUP
//
//  Created by Marc Fernández on 7/2/25.
//

import SwiftUI

struct MyTabView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            MainScreenView()
                .tabItem {
                    Label("Play", systemImage: "gamecontroller")
                }
            
            ChatListView()
                .tabItem {
                    Label("Chat", systemImage: "bubble")
                }
            
            if let currentUser = authManager.currentUser {
                MyUserView(user: currentUser)
                    .tabItem {
                        Label("User", systemImage: "person")
                    }
            }
        }
        .tabViewStyle(.automatic)
        .accentColor(Color(red: 0.9, green: 0.3, blue: 0.2))
        .environment(\.horizontalSizeClass, .compact) // Fuerza el comportamiento de iPhone
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    MyTabView()
        .environmentObject(AuthenticationManager.shared)
}
