//
//  ChatListView.swift
//  TeamUP
//
//  Created by Marc Fernández on 7/2/25.
//

import SwiftUI

// MARK: - Models
struct ChatPreview: Identifiable {
    let id = UUID()
    let username: String
    let lastMessage: String
    let timestamp: String
    let profileImage: String
}

// MARK: - View
struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - Ajustado para coincidir con otras vistas
                ZStack {
                    HStack {
                        Spacer()
                        Text("Team")
                            .font(.system(size: 28, weight: .bold)) +
                        Text("UP")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: 56)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                
                // Lista de chats
                List(viewModel.chats) { chat in
                    NavigationLink(destination: {
                        if let user = viewModel.findUser(withName: chat.username) {
                            ChatView(user: user)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Imagen de perfil
                            Image(chat.profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.username)
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text(chat.lastMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(chat.timestamp)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ChatListView()
}
