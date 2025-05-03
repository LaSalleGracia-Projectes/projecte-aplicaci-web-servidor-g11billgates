import Foundation
import Vapor
import Fluent
import FluentMongoDriver

final class User: Model, Content {
    static let schema = "users"
    
    @ID(custom: "_id") var id: ObjectId?
    @Field(key: "username") var username: String
    @Field(key: "password") var password: String
    @Field(key: "email") var email: String
    @Field(key: "age") var age: Int
    @Field(key: "swipes") var swipes: Int
    
    init() {}
    
    init(id: ObjectId? = nil, username: String, password: String, email: String, age: Int) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.age = age
        self.swipes = 0
    }
}

// MARK: - User Creation
extension User {
    struct Create: Content {
        let username: String
        let password: String
        let email: String
        let age: Int
    }
}

// MARK: - User Response
extension User {
    struct Public: Content {
        let id: String
        let username: String
        let email: String
        let age: Int
        let swipes: Int
        
        init(_ user: User) {
            self.id = user.id!.hexString
            self.username = user.username
            self.email = user.email
            self.age = user.age
            self.swipes = user.swipes
        }
    }
} 