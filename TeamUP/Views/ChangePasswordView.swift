import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChangePasswordViewModel()
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Cambiar contraseña")
                    .font(.title)
                    .padding(.top, 30)
                
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Contraseña")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        SecureField("", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Confirmar nueva contraseña")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        SecureField("", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    if newPassword == confirmPassword {
                        viewModel.changePassword(newPassword: newPassword)
                    } else {
                        viewModel.errorMessage = "Las contraseñas no coinciden"
                    }
                }) {
                    Text("Cambiar contraseña")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .alert("Contraseña actualizada", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu contraseña ha sido actualizada correctamente")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChangePasswordView()
} 