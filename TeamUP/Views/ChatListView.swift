//
//  ChatListView.swift
//  TeamUP
//
//  Created by Marc Fernández on 7/2/25.
//

import SwiftUI

// MARK: - Models
struct ChatPreview: Identifiable {
    let id: String
    let username: String
    let lastMessage: String
    let timestamp: String
    let profileImage: String
}

// MARK: - View
struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel(currentUserId: "current-user-id")
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                chatListView
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    private var headerView: some View {
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
    }
    
    private var chatListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    ChatRowView(chat: chat, viewModel: viewModel)
                }
            }
        }
    }
}

struct ChatRowView: View {
    let chat: ChatPreview
    let viewModel: ChatListViewModel
    
    var body: some View {
        NavigationLink(destination: {
            if let user = viewModel.findUser(withName: chat.username) {
                ChatView(chatId: chat.id, userId: user.id.uuidString, userAge: user.age)
            }
        }) {
            HStack(spacing: 12) {
                // Imagen de perfil
                AsyncImage(url: URL(string: chat.profileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
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
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
        }
        Divider()
    }
}

#Preview {
    ChatListView()
}
