import SwiftUI
// Asegúrate de que CustomStyles.swift esté en el mismo módulo o target
// No necesitas importación especial si está en el mismo módulo

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false
    @State private var navigateToTabView = false
    @State private var navigateToRegister = false  // Nuevo estado para la navegación al registro
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo
                    VStack(spacing: 0) {
                        Text("Team")
                            .font(.system(size: 40, weight: .bold)) +
                        Text("UP")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                    }
                    .padding(.bottom, 40)
                    
                    // Campos de entrada
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Usuario")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("Usuario", text: $viewModel.username)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                        
                        Text("Contraseña")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("Contraseña", text: $viewModel.password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.none)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Contraseña", text: $viewModel.password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.none)
                                    .autocapitalization(.none)
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Mensaje de error
                    if viewModel.showError {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .transition(.opacity)
                    }
                    
                    // Botón de inicio de sesión
                    Button(action: {
                        if viewModel.login() {
                            navigateToTabView = true
                        }
                    }) {
                        Text("Iniciar Sesión")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.9, green: 0.3, blue: 0.2))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Botones adicionales
                    VStack(spacing: 15) {
                        Button("¿Has olvidado tu contraseña?") {
                            viewModel.resetPassword()
                        }
                        .foregroundColor(.gray)
                        
                        HStack {
                            Text("¿No tienes cuenta?")
                                .foregroundColor(.gray)
                            Button("Regístrate") {
                                navigateToRegister = true
                            }
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.2))
                            .fontWeight(.bold)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToTabView) {
                MyTabView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
        }
    }
}


#Preview {
    LoginView()
}
