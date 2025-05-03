import Vapor

class UserController {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post(use: create)
        users.get(use: index)
        users.get(":userId", use: show)
        users.post(":userId", "swipe", use: incrementSwipes)
    }
    
    func incrementSwipes(req: Request) async throws -> User.Public {
        let userId = try req.parameters.require("userId", as: ObjectId.self)
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        user.swipes += 1
        try await user.save(on: req.db)
        return User.Public(user)
    }
} 