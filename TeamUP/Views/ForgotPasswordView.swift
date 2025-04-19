import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step = 1 // 1: Email, 2: Code and Password
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Icono y título
                VStack(spacing: 15) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 30)
                    
                    Text(step == 1 ? "Recuperar Contraseña" : "Verificar Código")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(step == 1 ? 
                         "Ingresa tu email para recibir un código de verificación" :
                         "Ingresa el código recibido y tu nueva contraseña")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Campos de entrada
                VStack(alignment: .leading, spacing: 15) {
                    if step == 1 {
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
                            
                            TextField("", text: $verificationCode)
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
                    if step == 1 {
                        viewModel.sendVerificationCode(email: email)
                        step = 2
                    } else {
                        if newPassword == confirmPassword {
                            viewModel.resetPassword(email: email, code: verificationCode, newPassword: newPassword)
                        } else {
                            viewModel.errorMessage = "Las contraseñas no coinciden"
                        }
                    }
                }) {
                    Text(step == 1 ? "Enviar código" : "Cambiar contraseña")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(step == 1 ? email.isEmpty : 
                         verificationCode.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                .opacity((step == 1 ? email.isEmpty : 
                         verificationCode.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                
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