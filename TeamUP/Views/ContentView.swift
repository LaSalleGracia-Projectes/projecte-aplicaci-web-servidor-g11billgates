import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        if authManager.isAuthenticated {
            MyTabView() // O la vista principal que quieras mostrar
        } else {
            LoginView()
        }
    }
} 