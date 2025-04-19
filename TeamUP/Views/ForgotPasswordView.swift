import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Icono y título
                VStack(spacing: 15) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .padding(.top, 30)
                    
                    Text(!viewModel.codeSent ? "Recuperar Contraseña" : "Verificar Código")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(!viewModel.codeSent ? 
                         "Ingresa tu email para recibir un código de verificación" :
                         "Ingresa el código recibido y tu nueva contraseña")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Campos de entrada
                VStack(alignment: .leading, spacing: 15) {
                    if !viewModel.codeSent {
                        // Campo de email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                    } else {
                        // Campo de código
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Código de verificación")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("", text: $code)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
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
                }
                .padding(.horizontal)
                
                // Botón de acción
                Button(action: {
                    if !viewModel.codeSent {
                        viewModel.sendVerificationCode(email: email)
                    } else {
                        if newPassword == confirmPassword {
                            viewModel.resetPassword(email: email, code: code, newPassword: newPassword)
                        } else {
                            viewModel.errorMessage = "Las contraseñas no coinciden"
                        }
                    }
                }) {
                    Text(!viewModel.codeSent ? "Enviar código" : "Cambiar contraseña")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(!viewModel.codeSent ? email.isEmpty : 
                         code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                .opacity((!viewModel.codeSent ? email.isEmpty : 
                         code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                
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