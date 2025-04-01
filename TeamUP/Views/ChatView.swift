import SwiftUI
import AVKit

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: String
    let isFromCurrentUser: Bool
}

// MARK: - Views
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    
    init(chatId: String, userId: String, userAge: Int) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId, userId: userId, userAge: userAge))
    }
    
    var body: some View {
        VStack {
            // Header
            headerView
            
            // Messages
            messagesView
            
            // Input area
            inputAreaView
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker(videoURL: $viewModel.selectedVideoURL)
        }
        .alert("Restricción de edad", isPresented: $viewModel.showAgeRestrictionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Debes ser mayor de 18 años para acceder al chat")
        }
        .onChange(of: viewModel.selectedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await viewModel.sendImage(image)
                }
            }
        }
        .onChange(of: viewModel.selectedVideoURL) { _, newURL in
            if let url = newURL {
                Task {
                    await viewModel.sendVideo(url)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Chat")
                .font(.system(size: 20, weight: .bold))
            
            Spacer()
            
            Color.clear
                .frame(width: 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
    
    private var inputAreaView: some View {
        HStack(spacing: 12) {
            // Media buttons
            HStack(spacing: 8) {
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    showVideoPicker = true
                }) {
                    Image(systemName: "video")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isRecording ? .red : .gray)
                }
            }
            
            // Text input
            TextField("Escribe un mensaje...", text: $viewModel.messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 8)
            
            // Send button
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }
}

struct MessageBubble: View {
    let message: Message
    let viewModel: ChatViewModel
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
                switch message.type {
                case .text:
                    Text(message.content)
                        .padding(12)
                        .background(message.isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                case .image:
                    if let url = message.mediaURL {
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200)
                                .cornerRadius(12)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                case .video:
                    if let url = message.mediaURL {
                        let player = AVPlayer(url: URL(string: url)!)
                        VideoPlayer(player: player)
                            .frame(width: 200, height: 150)
                            .cornerRadius(12)
                    }
                case .voice:
                    HStack {
                        Button(action: {
                            if let url = message.mediaURL {
                                viewModel.playVoiceMessage(URL(string: url)!)
                            }
                        }) {
                            Image(systemName: viewModel.audioPlayer?.isPlaying == true ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        if let duration = message.duration {
                            Text(String(format: "%.1f\"", duration))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Text(message.timestamp)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
    }
}
