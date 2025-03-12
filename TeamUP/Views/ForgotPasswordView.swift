import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var identifier = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Icono y título
                VStack(spacing: 15) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 30)
                    
                    Text("Recuperar Contraseña")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Ingresa tu email o nombre de usuario y la nueva contraseña")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Campos de entrada
                VStack(alignment: .leading, spacing: 15) {
                    // Campo de identificador
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email o nombre de usuario")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("", text: $identifier)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    // Campo de nueva contraseña
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nueva contraseña")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Campo de confirmación
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirmar contraseña")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal)
                
                // Botón de recuperación
                Button(action: {
                    if newPassword == confirmPassword {
                        viewModel.resetPassword(identifier: identifier, newPassword: newPassword)
                    } else {
                        viewModel.errorMessage = "Las contraseñas no coinciden"
                    }
                }) {
                    Text("Cambiar contraseña")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(identifier.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                .opacity((identifier.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Contraseña actualizada", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu contraseña ha sido actualizada correctamente")
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
} 