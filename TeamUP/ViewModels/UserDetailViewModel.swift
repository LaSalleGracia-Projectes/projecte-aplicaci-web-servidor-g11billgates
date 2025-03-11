import SwiftUI

class UserDetailViewModel: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
} 