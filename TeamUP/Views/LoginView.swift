import SwiftUI
// Asegúrate de que CustomStyles.swift esté en el mismo módulo o target
// No necesitas importación especial si está en el mismo módulo

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                HStack {
                    Text("Team")
                        .font(.system(size: 40, weight: .bold)) +
                    Text("UP")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                }
                .padding(.top, 60)
                
                // Campos de entrada
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email o nombre de usuario")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        TextField("", text: $identifier)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Contraseña")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        SecureField("", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                
                // Botón de olvidar contraseña
                HStack {
                    Spacer()
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("¿Has olvidado tu contraseña?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                    }
                }
                .padding(.horizontal, 32)
                
                // Botón de inicio de sesión
                Button(action: {
                    viewModel.login(identifier: identifier, password: password)
                }) {
                    Text("Iniciar sesión")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                // Separador
                HStack {
                    VStack { Divider() }
                    Text("O")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                
                // Botón de registro
                Button(action: {
                    showRegister = true
                }) {
                    Text("Crear cuenta nueva")
                        .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.9, green: 0.3, blue: 0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Mensaje de error
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 16)
                }
            }
            .navigationDestination(isPresented: $viewModel.loginSuccess) {
                MyTabView()
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    LoginView()
}
